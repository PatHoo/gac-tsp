variable "region_name" {
  description = "Name of region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "TSP"
}

variable "cluster_version" {
  description = "Cluster Version"
  type        = string
  default     = "1.23"
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "env_name" {
  description = "Name of Environment"
  type        = string
  default     = "NaN"
}

variable "eks_cluster_domain" {
  type        = string
  description = "Route53 domain for the cluster"
  default     = "vimmer.link"
}

variable "acm_certificate_domain" {
  type        = string
  description = "Route53 certificate domain"
  default     = "*.vimmer.link"
}
