terraform {
  required_providers {
    aws = {
        version = "~> 5.0"
    }
  }
}
provider "aws" {
    profile = "orion23"
    region = "sa-east-1"  
}