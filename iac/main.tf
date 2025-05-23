module lambda_s3_deploy {
  source = "./modules/lambda_s3_deploy"
}

#Outputs do módulo
output "lambda_arn" {
  value       = module.lambda_s3_deploy.lambda_function_arn
  description = "ARN da função Lambda implantada (referenciado do módulo)"
}

output "nome_do_bucket_s3" {
  value       = module.lambda_s3_deploy.lambda_code_bucket_name
  description = "Nome do bucket S3 do código Lambda (referenciado do módulo)"
}

output "nome_da_funcao_lambda" {
  value       = module.lambda_s3_deploy.lambda_function_name
  description = "Nome da função Lambda implantada (referenciado do módulo)"
}

output "arn_do_topico_sns" {
  value       = module.lambda_s3_deploy.sns_topic_arn
  description = "ARN do tópico SNS (referenciado do módulo)"
}
output "nome_do_topico_sns" {
  value       = module.lambda_s3_deploy.sns_topic_name
  description = "Nome do tópico SNS (referenciado do módulo)"
}






