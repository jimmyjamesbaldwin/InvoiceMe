provider "aws" {
  region = "us-east-1"
}

variable "app_name" {
  default = "InvoiceMe"
}

variable "bucket_name" {
  default = "bucket123"
}