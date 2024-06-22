#!/bin/bash

export $(cat .env | xargs)

docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY hashicorp/terraform destroy -auto-approve
