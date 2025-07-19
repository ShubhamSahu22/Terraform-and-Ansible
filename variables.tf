variable "region" {
  description = "AWS region where resources will be created"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public SSH key on your local system"
  type        = string
}