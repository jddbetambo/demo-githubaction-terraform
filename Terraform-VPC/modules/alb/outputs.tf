# Output the Bucket Name
output "alb_logs_bucket_name" {
  value = aws_s3_bucket.lb_logs.id
}