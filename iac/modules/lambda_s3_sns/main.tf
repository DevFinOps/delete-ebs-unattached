# Criação do Bucket S3
resource "aws_s3_bucket" "bucket_s3" {
  bucket = var.bucket_name

  force_destroy = true

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

# Criação da "pasta" lambda dentro do bucket
resource "aws_s3_object" "lambda_folder" {
  bucket = aws_s3_bucket.bucket_s3.bucket
  key    = "lambda/"
  
}

# Criação da "pasta" report dentro do bucket
resource "aws_s3_object" "report_folder" {
  bucket = aws_s3_bucket.bucket_s3.bucket
  key    = "report/"
  
}

# Upload dos scripts Python para a pasta "lambda" no Bucket S3
resource "aws_s3_object" "delete_ebs_file" {
  bucket = aws_s3_bucket.bucket_s3.id
  key    = "lambda/delete-ebs.zip"
  source = var.delete_ebs_zip_path
  etag   = filemd5(var.delete_ebs_zip_path)

  depends_on = [aws_s3_object.lambda_folder]
}

resource "aws_s3_object" "estimate_ebs_file" {
  bucket = aws_s3_bucket.bucket_s3.id
  key    = "lambda/estimate-ebs.zip"
  source = var.estimate_ebs_zip_path
  etag   = filemd5(var.estimate_ebs_zip_path)

  depends_on = [aws_s3_object.lambda_folder]
}

# Criação do topico SNS
resource "aws_sns_topic" "sns_topic" {
  name = var.sns_topic_name

  tags = merge(var.tags, {
    name        = "tf-sns-topic"
  })
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn 
  protocol  = "email"
  endpoint  = var.sns_email_endpoint 
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

# Criação das Funções Lambdas
resource "aws_lambda_function" "delete_ebs_function" {
  function_name = var.lambda_delete_ebs_function
  runtime      = var.lambda_runtime
  handler       = var.delete_ebs_handler
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  role          = aws_iam_role.iam_role.arn
  s3_bucket     = aws_s3_bucket.bucket_s3.id
  s3_key        = aws_s3_object.delete_ebs_file.key
  
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
                aws_s3_object.delete_ebs_file,
                aws_sns_topic.sns_topic
                ]
}

resource "aws_lambda_function" "estimate_ebs_function" {
  function_name = var.lambda_estimate_ebs_function
  runtime      = var.lambda_runtime
  handler       = var.estimate_ebs_handler
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  role          = aws_iam_role.iam_role.arn
  s3_bucket     = aws_s3_bucket.bucket_s3.id
  s3_key        = aws_s3_object.estimate_ebs_file.key
  
  # Criando variaveis de ambiente que vão ser usadas pelo codigo python também
  environment {
    variables = {
      TARGET_BUCKET_S3 = aws_s3_bucket.bucket_s3.id
    }
  }

  tags = merge(var.tags, {
    name        = "tf-lambda"
  })
  
  depends_on = [aws_s3_object.estimate_ebs_file]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
