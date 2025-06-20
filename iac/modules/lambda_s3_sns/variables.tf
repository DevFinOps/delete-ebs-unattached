## Informações do Bucket ##
variable "bucket_name" {
  type        = string
  description = "Nome do bucket"
  default     = "devfinops.tf.bucket.delete-ebs-unattached"
}

## Informações do SNS ##
variable "sns_topic_name" {
  type        = string
  description = "Nome do tópico SNS"
  default     = "devfinops_tf_sns_delete-ebs-unattached"
}

variable "sns_email_endpoint" {
  type        = string
  description = "Endereço de e-mail para receber notificações do SNS"
  default     = "" ##Substitua pelo seu e-mail
}

## Informações do IAM ##
variable "iam_role_name" {
  type        = string
  description = "Nome da role IAM"
  default     = "devfinops.tf.iam_role"
}

variable "iam_role_policy_name" {
  type        = string
  description = "Nome da policy IAM"
  default     = "devfinops.tf.iam_role_policy"
}

## Informações da Lambda ##
variable "regions"{
  type        = list(string)
  description = "Regiões onde a lambda precisa verificar EBS não anexados"
  default     = ["us-east-1", "sa-east-1"] 
}

variable "lambda_name" {
  type        = string
  description = "Nome da função Lambda"
  default     = "devfinops_tf_lambda_delete_ebs_unattached"
}

variable "lambda_handler" {
  type        = string
  description = "Função handler da lambda"
  default     = "delete_ebs_noAttached.handler"
}

variable "lambda_memory_size" {
  type        = number
  description = "Tamanho da memória da função Lambda"
  default     = 128 ##Como padrão será 128MB, mas altere conforme necessidade
}

variable "lambda_timeout" {
  type        = number
  description = "Tempo de timeout da função Lambda"
  default     = 60 ##Como padrão será 60 segundos, mas altere conforme necessidade
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime da função Lambda"
  default     = "python3.9"
}

variable "lambda_zip_path" {
  type        = string
  description = "Caminho do arquivo zip da função Lambda"
  default     = "./python.zip"
}

## Informações de Tags ##
variable "tags" {
  type        = map(string)
  description = "Tags para os recursos"
  default     = {
    application = "IaC-Terraform"
    project = "DevFinOps-Project"
  }
}