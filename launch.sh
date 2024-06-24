#!/bin/bash

#copy myKey.pem dans ansible/playbooks
cp myKey.pem ansible/playbook/myKey.pem

AWS_INSTANCE_NUMBER=1 #default value

cp -r http/conf ansible/playbook/conf

cp -r db ansible/playbook/db

cp -r prometheus ansible/playbook/prometheus

cp -r grafana ansible/playbook/grafana

#récupérer les variable d'environnement du fichier .env et les ajouter sur le pc
export $(cat .env | xargs)

docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER hashicorp/terraform init
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER hashicorp/terraform plan
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER hashicorp/terraform apply -auto-approve > tmp/output.txt

# Extraire les valeurs de app_server_public_dns
app_server_public_dns=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_dns =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))
# Extraire les valeurs de app_server_public_ip
app_server_public_ip=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_ip =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))

echo "[managers]" > ansible/playbook/inventory.ini
echo "manager ansible_host=${app_server_public_dns[0]} aws_ip=${app_server_public_ip[0]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini

echo "[workers]" >> ansible/playbook/inventory.ini
for ((i=1; i<${#app_server_public_dns[@]}; i++)); do
    echo "worker$i ansible_host=${app_server_public_dns[$i]} aws_ip=${app_server_public_ip[$i]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini
done

docker build -t ansible-container ./ansible

docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml

response=$(curl -u admin:unMotDePasseSécurisé -X POST -H "Content-Type: application/json" -d '{"name":"APIKey", "role": "Admin"}' "http://${app_server_public_dns[0]}:3000/api/auth/keys")

cle_grafana=$(echo $response | jq -r '.key')

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${cle_grafana}" -d '{
  "name": "datasource",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://${app_server_public_dns[0]}",
  "basicAuth": false
}' "http://${app_server_public_dns[0]}:3000/api/datasources"

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${cle_grafana}" -d @grafana/dashboard/home.json "http://${app_server_public_dns[0]}:3000/api/dashboards/db"