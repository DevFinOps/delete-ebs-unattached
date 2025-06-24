import os
import pandas as pd
from io import StringIO
from boto3 import client
from datetime import datetime, timedelta
from logging import basicConfig, info, error, INFO

#Variaveis de ambiente passadas através do AWS Lambda
BUCKET_NAME = os.environ.get("TARGET_BUCKET_S3")
FOLDER_PREFIX = os.environ.get("TARGET_BUCKET_S3_FOLDER")

#Criando um logging para o código
basicConfig(level=INFO, format="%(asctime)s - %(levelname)s - %(message)s")

#Função responsavel em ler o arquivo csv gerado pelo script delete ebs
def get_data_csv_report_file():
  s3 = client('s3')

  latest_file = None
  latest_modified_time = datetime.min
  list_id_resources = []  

  try:
    response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=FOLDER_PREFIX)

    if 'Contents' in response:
        for obj in response['Contents']:
            # Verifica se é um arquivo CSV e não é a própria pasta (que geralmente termina com /)
            if obj['Key'].endswith('.csv') and not obj['Key'].endswith('/'):
                if obj['LastModified'].replace(tzinfo=None) > latest_modified_time:
                    latest_modified_time = obj['LastModified'].replace(tzinfo=None)
                    latest_file = obj['Key']

    if not latest_file:
        error(f"Nenhum arquivo CSV encontrado na pasta {FOLDER_PREFIX} do bucket {BUCKET_NAME}.")
        return None
    
    # Obtem o conteúdo do arquivo
    obj_content = s3.get_object(Bucket=BUCKET_NAME, Key=latest_file)
    file_body = obj_content['Body'].read().decode('utf-8')
    
    info("Transformando o objeto string em csv")
    df = pd.read_csv(StringIO(file_body))
    
    info("Retornando a lista de IDs de recursos")
    list_id_resources = df['VolumeId'].tolist() 
    
    return list_id_resources
    
  except Exception as e:
    error(f"Ocorreu um erro ao acessar o S3: {e}")
    return None


def get_daily_cost_for_resource(resource_id, start_date, end_date):
    """
    Consulta o AWS Cost Explorer para obter o custo diário de um recurso específico.
    """
    ce = client('ce')

    try:
        response = ce.get_cost_and_usage_with_resources(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity= 'DAILY',
            Metrics=[
                'UnblendedCost',
            ],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'RESOURCE_ID'},
                {'Type': 'DIMENSION', 'Key': 'RECORD_TYPE'},
            ],
            Filter={
                'Dimensions': {'Key': 'RECORD_TYPE', 'Values': ['Usage']}
            }                
        )

        costs = {}
        for result_by_time in response['ResultsByTime']:
            date = result_by_time['TimePeriod']['Start']
            # O custo vem como string, converte para float
            for group in result_by_time['Groups']:
                actual_resource_id = group['Keys'][0]
                actual_record_type = group['Keys'][1]

                if actual_resource_id == resource_id and actual_record_type == 'Usage':
                    amount = float(group['Metrics']['UnblendedCost']['Amount'])
                    costs[date] = amount
                    break
        return costs

    except Exception as e:
        print(f"Erro ao obter custo para o recurso {resource_id}: {e}")
        return None


# funcao lambda principal
def handler(event, context):
  try:
    info("Iniciando o processo de estimativa de EBS sem volumes anexados.")
    
    resources = get_data_csv_report_file()
    
    for resource in resources:
      info(f"Consultando custo diário para o recurso {resource}")
      start_date = (datetime.now() - timedelta(days=14)).strftime('%Y-%m-%d')
      end_date = datetime.now().strftime('%Y-%m-%d')
      
      daily_costs = get_daily_cost_for_resource(str(resource), start_date, end_date)
      
      if daily_costs:
        info(f"Custo diário para o recurso {resource}: {daily_costs}")
      else:
        error(f"Não foi possível obter o custo para o recurso {resource}")

    info("Concluido com sucesso!")
    
    return {
            'statusCode': 200,
            'body': "Sucesso"
        }

  except Exception as e:
    error(f"Erro capturado {e}")
    
    return {
            'statusCode': 500,
            'body': f'Erro capturado: {e}'
        }