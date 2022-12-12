# tflint-ignore: terraform_unused_declarations
variable "cluster_name" {
  description = "Name of cluster - used by Terratest for e2e test automation"
  type        = string
  default     = "TSP"
}

variable "region_name" {
  description = "Name of region"
  type        = string
  default     = "ap-southeast-1"
}

