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