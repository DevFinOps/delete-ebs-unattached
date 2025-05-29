import os
import csv
import json
import boto3
from io import StringIO
from datetime import datetime
from logging import basicConfig, info, error, INFO

#Variaveis de ambiente passadas através do AWS Lambda
BUCKET_NAME = os.environ.get("TARGET_BUCKET_S3")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
REGIONS = os.environ.get("TARGET_REGIONS", "[]")

#Criando um logging para o código
basicConfig(level=INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def upload_file_to_s3(file_path, bucket_name, object_name) -> bool:
    '''
    Realiza o upload de um arquivo para um Bucket S3.

    :param file_path: Caminho completo para o arquivo local a ser enviado.
    :param bucket_name: Nome do bucket S3 de destino.
    :param object_name: Nome do objeto S3 (caminho completo no bucket).
                        Se não for fornecido, o nome base do file_path será usado.
    :return: True se o upload for bem-sucedido, False caso contrário.
    '''

    client = boto3.client("s3")
    
    if not bucket_name:
        error("O nome do bucket S3 não foi fornecido verificar as variaveis de ambiente.")
        return False

    try:
        info(f"Realizando upload do arquivo {file_path} para o bucket S3 s3//{bucket_name}")
        client.put_object(Bucket=bucket_name, Key=object_name, Body=file_path)
        info(f"Upload do arquivo {file_path} concluído com sucesso.")
        return True
    
    except Exception as e:
        error(f"Ocorreu um erro inesperado durante o upload: {e}")
        return False
    
def send_email(
    count_ebs_excluidos_por_regiao,
    count_ebs_nao_excluidos_por_regiao,
    ebs_nao_excluidos,
):
    # Publicar mensagem no tópico SNS
    sns_topic_arn = SNS_TOPIC_ARN
    if not sns_topic_arn:
        error("O ARN do tópico SNS não foi fornecido verificar as variaveis de ambiente.")
        return
    sns_client = boto3.client("sns")

    # Formatando a mensagem para incluir o número de EBS excluídos e não excluídos em cada região
    message = "Olá,\n\n"
    message += (
        "A função Lambda para exclusão de EBS unattached foi executada com sucesso!\n\n"
    )
    message += "Aqui está um resumo dos resultados:\n\n"
    message += "Região\t\tExcluídos\tNão Excluídos\n"
    message += "--------------------------------------------------\n"
    for regiao, count_excluidos in count_ebs_excluidos_por_regiao:
        count_nao_excluidos = next(
            (
                count
                for reg, count in count_ebs_nao_excluidos_por_regiao
                if reg == regiao
            ),
            0,
        )
        message += f"{regiao}\t\t{count_excluidos}\t\t{count_nao_excluidos}\n"
    message += "--------------------------------------------------\n"
    message += f"Total de EBS verificados: {sum([count for _, count in count_ebs_excluidos_por_regiao]) + sum([count for _, count in count_ebs_nao_excluidos_por_regiao])}.\n"
    message += f"Total de EBS excluídos: {sum([count for _, count in count_ebs_excluidos_por_regiao])}.\n"
    message += f"Total de EBS não excluídos: {sum([count for _, count in count_ebs_nao_excluidos_por_regiao])}.\n"

    subject = "Resumo da exclusão de Volumes EBS unattached na conta: Observability-dev"

    sns_client.publish(TopicArn=sns_topic_arn, Message=message, Subject=subject)


def create_csv_file(dict_data):
    '''
    Cria um arquivo CSV a partir de um dicionário de dados.

    :param dict_data: Dicionário contendo os dados a serem escritos no arquivo CSV.
    '''

    # Criar um objeto StringIO para armazenar os dados CSV em memória
    output_file = StringIO()

    header_list = list(dict_data[0].keys())

    csv_writer = csv.DictWriter(output_file, fieldnames=header_list)
    csv_writer.writeheader() #Cabeçalho do CSV
    csv_writer.writerows(dict_data) #Escreve os dados no CSV

    csv_file = output_file.getvalue() #Obtendo os dados do CSV
    info(f"CSV criado com {len(dict_data)} registros")
    output_file.close() 

    return csv_file


# funcao lambda principal
def handler(event, context):
    count_ebs_excluidos_por_regiao = (
        []
    )  # lista para armazenar o número de EBS excluídos em cada região
    count_ebs_nao_excluidos_por_regiao = (
        []
    )  # lista para armazenar o número de EBS não excluídos em cada região

    volumes_list = []
    
    regions = json.loads(REGIONS)
    for region in regions:
        print(f"#### {region} ####")

        # Criar uma instancia do client EC2
        ec2 = boto3.client("ec2", region_name=region)

        # Inicializar listas
        ebs_excluidos = []
        ebs_nao_excluidos = []

        # Inicializar contador
        count_ebs_excluidos = 0
        count_ebs_nao_excluidos = 0

        # Iterar sobre todos os volumes EBS na região
        paginator = ec2.get_paginator("describe_volumes")
        for page in paginator.paginate():
            for volume in page["Volumes"]:
                # Verificar se o volume não está anexado a uma instância
                if not volume["Attachments"]:
                    # Criar um dicionário com as tags para facilitar a verificação
                    tags = {tag["Key"]: tag["Value"] for tag in volume.get("Tags", [])}

                    # Verificar se o volume possui a tag 'inUse' com valor True
                    if "inUse" in tags and tags["inUse"].lower() == "true":
                        print(
                            f'Volume {volume["VolumeId"]} não pode ser excluído pois está marcado como em uso'
                        )
                        ebs_nao_excluidos.append(volume["VolumeId"])
                        count_ebs_nao_excluidos += 1
                    else:
                    #Inclusao dos ebs que vao ser excluidos em uma lista para posterior upload em bucket s3    
                        volumes_list.append({
                            "VolumeId":volume["VolumeId"],
                            "VolumeType":volume["VolumeType"],
                            "Region":volume["AvailabilityZone"],
                            "SizeGb":volume["Size"],
                            "State":volume["State"],
                            "Iops":volume.get("Iops",'N/A'),
                            "Tags":tags,
                            })
                        info(f'Volume {volume["VolumeId"]} incluso na listagem para exclusão')
                        
                        # Se o volume não possuiu a tag 'inUse', pode ser excluído
                        # ec2.delete_volume(VolumeId=volume["VolumeId"])
                        print(f'Volume {volume["VolumeId"]} excluído com sucesso')
                        ebs_excluidos.append(volume["VolumeId"])
                        count_ebs_excluidos += 1
                else:
                    # Se o volume está anexado a uma instância
                    print(f'O volume {volume["VolumeId"]} está anexado a uma instância')
                    ebs_nao_excluidos.append(volume["VolumeId"])
                    count_ebs_nao_excluidos += 1

        # Imprimir listas e contador
        print("\nEBS Excluídos:")
        print("\n".join(ebs_excluidos))

        print("\nEBS Não Excluídos:")
        print("\n".join(ebs_nao_excluidos))

        print(f"\nNúmero total de EBS excluídos: {count_ebs_excluidos}")
        print(f"Número total de EBS não excluídos: {count_ebs_nao_excluidos}")

        # Adicionar o número de EBS excluídos e não excluídos na região à lista
        count_ebs_excluidos_por_regiao.append((region, count_ebs_excluidos))
        count_ebs_nao_excluidos_por_regiao.append((region, count_ebs_nao_excluidos))

    # enviar um email com o número de EBS excluídos e não excluídos em cada região
    send_email(
        count_ebs_excluidos_por_regiao,
        count_ebs_nao_excluidos_por_regiao,
        ebs_nao_excluidos,
    )

    # Criando arquivo CSV com os volumes que foram excluídos
    csv_file = create_csv_file(volumes_list)
    if not csv_file:    
        error("Erro ao criar o arquivo CSV")
        return {
            'statusCode': 500,
            'body': 'Erro ao criar o arquivo CSV'
        }
    
    # Definindo o nome do arquivo CSV
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    csv_object_key = f"unattached_ebs_{timestamp}.csv"

    if not BUCKET_NAME:
            error("O nome do bucket S3 não foi fornecido verificar as variaveis de ambiente.")
            return {
                'statusCode': 500,
                'body': 'O nome do bucket S3 não foi fornecido verificar as variaveis de ambiente.'
            }
        
    if upload_file_to_s3(csv_file, BUCKET_NAME, csv_object_key):
        info(f"Arquivo CSV {csv_object_key} enviado para o bucket S3 {BUCKET_NAME} com sucesso.")
        return {
            'statusCode': 200,
            'body': f'Arquivo CSV {csv_object_key} enviado para o bucket S3 {BUCKET_NAME}.'
        }
    else:
        error(f"Falha ao enviar o arquivo CSV {csv_object_key} para o bucket S3 {BUCKET_NAME}.")
        return {
            'statusCode': 500,
            'body': 'Falha ao enviar o arquivo CSV para o bucket S3.'
        }
