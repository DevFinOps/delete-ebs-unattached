output "delete_ebs_function_arn" {
  value       = aws_lambda_function.delete_ebs_function.arn
  description = "ARN da função Lambda delete ebs criada"
}

output "estimate_ebs_function_arn" {
  value       = aws_lambda_function.estimate_ebs_function.arn
  description = "ARN da função Lambda estimate ebs criada"
}

output "lambda_code_bucket_name" {
  value       = aws_s3_bucket.bucket_s3.id
  description = "Nome do bucket S3 para o código da Lambda"
}

output "delete_ebs_function_name" {
  value       = aws_lambda_function.delete_ebs_function.function_name
  description = "Função Lambda que percorre o ambiente identificando os ebs desatachados"
}

output "estimate_ebs_function_name" {
  value       = aws_lambda_function.estimate_ebs_function.function_name
  description = "Função Lambda que percorre o ambiente identificando os ebs desatachados"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.sns_topic.arn
  description = "ARN do tópico SNS criado"
}

output "sns_topic_name" {
  value       = aws_sns_topic.sns_topic.name
  description = "Nome do tópico SNS criado"
}

output "sns_subscription_arn" {
  value       = aws_sns_topic_subscription.email_subscription.arn
  description = "ARN da assinatura do SNS criada"
}