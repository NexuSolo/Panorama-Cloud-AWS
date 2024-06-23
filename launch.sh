#!/bin/bash

#copy myKey.pem dans ansible/playbooks
cp myKey.pem ansible/playbook/myKey.pem

cp -r http/conf ansible/playbook/conf

cp -r db ansible/playbook/db

cp -r prometheus ansible/playbook/prometheus

cp -r grafana ansible/playbook/grafana

#récupérer les variable d'environnement du fichier .env et les ajouter sur le pc
export $(cat .env | xargs)

docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY hashicorp/terraform init
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY hashicorp/terraform plan
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY hashicorp/terraform apply -auto-approve > tmp/output.txt

# Extraire les valeurs de app_server_public_dns
app_server_public_dns=($(grep -A 2 "app_server_public_dns =" tmp/output.txt | tail -n 2 | awk -F '"' '{print $2}'))
# Extraire les valeurs de app_server_public_ip
app_server_public_ip=($(grep -A 2 "app_server_public_ip =" tmp/output.txt | tail -n 2 | awk -F '"' '{print $2}'))

echo "[managers]" > ansible/playbook/inventory.ini
echo "manager ansible_host=${app_server_public_dns[0]} aws_ip=${app_server_public_ip[0]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini

echo "[workers]" >> ansible/playbook/inventory.ini
for ((i=1; i<${#app_server_public_dns[@]}; i++)); do
    echo "worker$i ansible_host=${app_server_public_dns[$i]} aws_ip=${app_server_public_ip[$i]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini
done

docker build -t ansible-container ./ansible

docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml