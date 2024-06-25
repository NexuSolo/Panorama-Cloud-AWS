#!/bin/bash

cp myKey.pem ansible/playbook/myKey.pem

AWS_INSTANCE_NUMBER=2 #default value

cp -r http/conf ansible/playbook/conf

cp -r db ansible/playbook/db

cp -r prometheus ansible/playbook/prometheus

export $(cat .env | xargs)

# Exécute le script Terraform

docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform init
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform plan
# Exécute le script Terraform et redirige la sortie vers un fichier temporaire
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform apply -auto-approve > tmp/output.txt

#generate inventory.ini

app_server_public_dns=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_dns =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))
app_server_public_ip=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_ip =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))

echo "[managers]" > ansible/playbook/inventory.ini
echo "manager ansible_host=${app_server_public_dns[0]} aws_ip=${app_server_public_ip[0]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini

echo "[workers]" >> ansible/playbook/inventory.ini
for ((i=1; i<${#app_server_public_dns[@]}; i++)); do
    echo "worker$i ansible_host=${app_server_public_dns[$i]} aws_ip=${app_server_public_ip[$i]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini
done

docker build -t ansible-container ./ansible

# Exécute le playbook Ansible
docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml

# Vérifie si la commande a échoué
if [ $? -ne 0 ]; then
    echo "La première tentative a échoué, tentative de relance..."
    # Tente d'exécuter la commande une seconde fois
    docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml
fi