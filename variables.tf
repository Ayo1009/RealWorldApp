# AWS Credentials
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

# App Domain
variable "app_domain_name" {
  description = "Domain name for the RealWorld App"
  type        = string
}
