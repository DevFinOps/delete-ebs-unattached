# Criação do Bucket S3
resource "aws_s3_bucket" "bucket_s3" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    name        = "tf-bucket"
  })
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket_s3.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Criação da "pasta" script dentro do bucket
resource "aws_s3_object" "script_folder" {
  bucket = aws_s3_bucket.bucket_s3.bucket
  key    = "script/"
  
}

# Upload do script Python para a pasta "script" no Bucket S3
resource "aws_s3_object" "script_file" {
  bucket = aws_s3_bucket.bucket_s3.id
  key    = "script/python.zip"
  source = var.lambda_zip_path
  etag   = filemd5(var.lambda_zip_path)

  depends_on = [aws_s3_object.script_folder]
}

# Criação do topico SNS
resource "aws_sns_topic" "sns_topic" {
  name = var.sns_topic_name

  tags = merge(var.tags, {
    name        = "tf-sns-topic"
  })
}

# Criação da Role IAM para a função Lambda
resource "aws_iam_role" "iam_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }, 
    ]
  })

  tags = merge(var.tags, {
    name        = "tf-role"
  })
}

#Criação da Policy IAM
resource "aws_iam_role_policy" "iam_role_policy" {
  name = var.iam_role_policy_name
  role = aws_iam_role.iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" # Mais robusto que *:*
      },
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DeleteVolume",
        ],
        Effect   = "Allow",
        Resource = "*" 
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject" 
        ],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket_s3.id}/*"
      },
      {
        Action = [
          "sns:Publish"
        ],
        Effect   = "Allow",
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })
}

# Criação da Função Lambda
resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_name
  runtime      = var.lambda_runtime
  handler       = var.lambda_handler
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  role          = aws_iam_role.iam_role.arn
  s3_bucket     = aws_s3_bucket.bucket_s3.id
  s3_key        = aws_s3_object.script_file.key
  
  # Criando variaveis de ambiente que vão ser usadas pelo codigo python também
  environment {
    variables = {
      TARGET_BUCKET_S3 = aws_s3_bucket.bucket_s3.id
      SNS_TOPIC_ARN = aws_sns_topic.sns_topic.arn
      TARGET_REGIONS = jsonencode(var.regions)
    }
  }

  tags = merge(var.tags, {
    name        = "tf-lambda"
  })
  
  depends_on = [
                aws_s3_object.script_file,
                aws_sns_topic.sns_topic
                ]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
