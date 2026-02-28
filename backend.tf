

 terraform {
  backend "s3" {
    bucket         = "lumbenlengo-terraform-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock" 
  }
}