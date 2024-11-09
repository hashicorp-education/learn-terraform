# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  /*cloud {
    organization = "lb-terraform-prd"

    workspaces {
      name = "learn-terraform"
      project = "learn-terraform-prj"
    }
  }*/

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }

  required_version = ">= 1.2"
}
