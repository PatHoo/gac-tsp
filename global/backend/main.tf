provider "aws" {
  region = local.region
}

locals {
  region          = var.region_name
}

resource "aws_s3_bucket" "tsp-bucket" {
  bucket = "tsp-${var.env_name}-bucket"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "tsp-StateTable" {
  name           = "tsp-${var.env_name}-StateTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
