output "upload_bucket_name" {
  description = "Name of the upload S3 bucket"
  value       = aws_s3_bucket.upload.bucket
}

output "upload_bucket_arn" {
  description = "ARN of the upload S3 bucket (used by IAM policies)"
  value       = aws_s3_bucket.upload.arn
}

output "upload_bucket_domain" {
  description = "Regional domain of the upload bucket"
  value       = aws_s3_bucket.upload.bucket_regional_domain_name
}

output "processed_bucket_name" {
  description = "Name of the processed S3 bucket"
  value       = aws_s3_bucket.processed.bucket
}

output "processed_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  value       = aws_s3_bucket.processed.arn
}

output "processed_bucket_domain" {
  description = "Regional domain of the processed bucket (CloudFront origin)"
  value       = aws_s3_bucket.processed.bucket_regional_domain_name
}
