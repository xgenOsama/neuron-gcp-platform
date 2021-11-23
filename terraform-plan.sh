#! /bin/bash
terraform plan -no-color -input=false -var-file=default.tfvars  | tee ./target/terraform-plan-$(date +'%Y-%m-%d_%H:%M:%S').txt