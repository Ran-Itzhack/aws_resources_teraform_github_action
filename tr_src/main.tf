terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.1.7"

  ##
  # Updated to match your first error fix:
  ##

  # required_version = ">= 1.4.0" 

}

provider "aws" {
  alias      = "ohio"
  region     = "us-east-2"
  # access_key = var.access_key
  # secret_key = var.secret_key
}


module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr 
  
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
}
