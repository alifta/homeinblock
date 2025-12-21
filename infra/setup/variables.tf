variable "tf_state_bucket" {
  description = "The name of the S3 bucket to store the Terraform TF state"
  default     = "devops-homeinblock-tf-state"
}

variable "tf_state_lock_table" {
  description = "The name of the DynamoDB table for TF state locking"
  default     = "devops-homeinblock-tf-lock"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "homeinblock-app-api"
}

variable "contact" {
  description = "Contact email for tagging resources"
  default     = "farrokhtalat@gmail.com"
}