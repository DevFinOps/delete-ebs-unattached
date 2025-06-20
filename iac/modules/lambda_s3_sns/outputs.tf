output "lambda_function_arn" {
  value       = aws_lambda_function.lambda_function.arn
  description = "ARN da função Lambda criada"
}

output "lambda_code_bucket_name" {
  value       = aws_s3_bucket.bucket_s3.id
  description = "Nome do bucket S3 para o código da Lambda"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda_function.function_name
  description = "Nome da função Lambda criada"
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