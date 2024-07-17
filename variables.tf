# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  default     = "us-west-1"
}

variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t2.micro"
}

variable "instance_name" {
  description = "EC2 instance name"
  default     = "Provisioned by Terraform"
}

variable "db_name" {
  description = "DB Name"
  default     = "db-claire"
}

variable "username" {
  description = "DB Username"
  default     = "claire_db"
}

variable "password" {
  description = "DB Password"
  default     = "3g_yI81udju#cc|pqep"
}
