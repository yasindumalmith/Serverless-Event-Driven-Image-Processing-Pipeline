terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote state — values from bootstrap step
  backend "s3" {
    bucket         = "img-pipeline-tfstate-4eb076a2" # ← paste from bootstrap output
    key            = "image-pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # Tags applied to every resource automatically
  default_tags {
    tags = {
      Project     = "image-pipeline"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Generate a random suffix for globally unique S3 bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

module "iam" {
  source = "./modules/iam"

  project     = var.project
  environment = var.environment

  upload_bucket_arn    = module.s3.upload_bucket_arn
  processed_bucket_arn = module.s3.processed_bucket_arn
  dynamodb_table_arn   = module.dynamodb.table_arn


  # We pass placeholder ARNs for now — these will be replaced
  # with real ARNs as we build the S3, DynamoDB, SQS, SNS modules

  resize_queue_arn      = module.sqs.resize_queue_arn
  watermark_queue_arn   = module.sqs.watermark_queue_arn
  rekognition_queue_arn = module.sqs.rekognition_queue_arn
}

# ── S3 module ─────────────────────────────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  project     = var.project
  environment = var.environment
  suffix      = random_id.suffix.hex
}

# ── DynamoDB module ───────────────────────────────────────────────────────────
module "dynamodb" {
  source = "./modules/dynamodb"

  project     = var.project
  environment = var.environment
}

# ── Cognito module ────────────────────────────────────────────────────────────
module "cognito" {
  source = "./modules/cognito"

  project     = var.project
  environment = var.environment

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]
}

# ── Lambda module ─────────────────────────────────────────────────────────────
module "lambda" {
  source = "./modules/lambda"

  project     = var.project
  environment = var.environment

  upload_bucket_name    = module.s3.upload_bucket_name
  upload_bucket_arn     = module.s3.upload_bucket_arn
  processed_bucket_name = module.s3.processed_bucket_name
  dynamodb_table_name   = module.dynamodb.table_name

  presign_role_arn = module.iam.presign_role_arn
  status_role_arn  = module.iam.status_role_arn
  trigger_role_arn = module.iam.trigger_role_arn

  resize_queue_url      = module.sqs.resize_queue_url
  watermark_queue_url   = module.sqs.watermark_queue_url
  rekognition_queue_url = module.sqs.rekognition_queue_url
}

# ── API Gateway module ────────────────────────────────────────────────────────
module "api_gateway" {
  source = "./modules/api-gateway"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_app_client_id = module.cognito.app_client_id

  presign_function_name = module.lambda.presign_function_name
  presign_invoke_arn    = module.lambda.presign_invoke_arn
  status_function_name  = module.lambda.status_function_name
  status_invoke_arn     = module.lambda.status_invoke_arn
}

# ── SQS module ────────────────────────────────────────────────────────────────
module "sqs" {
  source = "./modules/sqs"

  project     = var.project
  environment = var.environment
}



