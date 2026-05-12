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
    bucket         = "img-pipeline-tfstate-2fa0e315" # ← paste from bootstrap output
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
