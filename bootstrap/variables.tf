variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  default     = "290459632348-s3-bucket-001"
}
