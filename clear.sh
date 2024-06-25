#!/bin/bash

AWS_INSTANCE_NUMBER=2 #default value

export $(cat .env | xargs)

docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_region=$AWS_REGION hashicorp/terraform destroy -auto-approve
