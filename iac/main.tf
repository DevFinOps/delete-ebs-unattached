module lambda_s3_sns {
  source = "./modules/lambda_s3_sns"
}

#Outputs do módulo
output "delete_ebs_arn" {
  value       = module.lambda_s3_sns.delete_ebs_function_arn
  description = "ARN da função Lambda delete EBS não anexados (referenciado do módulo)"
}

output "estimate_ebs_arn" {
  value       = module.lambda_s3_sns.estimate_ebs_function_arn
  description = "ARN da função Lambda estimate EBS não anexados (referenciado do módulo)"
}

output "nome_do_bucket_s3" {
  value       = module.lambda_s3_sns.lambda_code_bucket_name
  description = "Nome do bucket S3 do código Lambda (referenciado do módulo)"
}

output "lambda_delete_ebs_function_name" {
  value       = module.lambda_s3_sns.delete_ebs_function_name
  description = "Nome da função Lambda delete ebs implantada (referenciado do módulo)"
}

output "lambda_estimate_ebs_function_name" {
  value       = module.lambda_s3_sns.estimate_ebs_function_name
  description = "Nome da função Lambda estimate ebs implantada (referenciado do módulo)"
}

output "arn_do_topico_sns" {
  value       = module.lambda_s3_sns.sns_topic_arn
  description = "ARN do tópico SNS (referenciado do módulo)"
}
output "nome_do_topico_sns" {
  value       = module.lambda_s3_sns.sns_topic_name
  description = "Nome do tópico SNS (referenciado do módulo)"
}
output "arn_sns_subscription" {
  value       = module.lambda_s3_sns.sns_subscription_arn
  description = "ARN da assinatura do SNS (referenciado do módulo)"
}






