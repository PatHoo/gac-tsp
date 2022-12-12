# Output bucket name
output "bucket_name" {
  value       = aws_s3_bucket.tsp-bucket.bucket
}
