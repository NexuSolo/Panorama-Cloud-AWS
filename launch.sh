cp myKey.pem ansible/playbook/myKey.pem
echo "Étape 1: Clé SSH copiée."

AWS_INSTANCE_NUMBER=2 #default value

cp -r http/conf ansible/playbook/conf
echo "Étape 2: Configuration HTTP copiée."

cp -r db ansible/playbook/db
echo "Étape 3: Base de données copiée."

cp -r prometheus ansible/playbook/prometheus
echo "Étape 4: Configuration Prometheus copiée."

export $(cat .env | xargs)
echo "Étape 5: Variables d'environnement exportées."

echo "Préparation à l'exécution de Terraform..."
echo "-------------------------------------------"
echo "Étape 6: Initialisation de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform init

echo "Étape 7: Planification de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform plan

echo "Étape 8: Application de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform apply -auto-approve > tmp/output.txt
echo "Terraform appliqué avec succès."

echo "Génération de l'inventaire Ansible..."

app_server_public_dns=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_dns =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))
app_server_public_ip=($(grep -A $AWS_INSTANCE_NUMBER "app_server_public_ip =" tmp/output.txt | tail -n $AWS_INSTANCE_NUMBER | awk -F '"' '{print $2}'))

echo "[managers]" > ansible/playbook/inventory.ini
echo "manager ansible_host=${app_server_public_dns[0]} aws_ip=${app_server_public_ip[0]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini

echo "[workers]" >> ansible/playbook/inventory.ini
for ((i=1; i<${#app_server_public_dns[@]}; i++)); do
    echo "worker$i ansible_host=${app_server_public_dns[$i]} aws_ip=${app_server_public_ip[$i]} ansible_user=ubuntu ansible_ssh_private_key_file=myKey.pem" >> ansible/playbook/inventory.ini
done
echo "Inventaire Ansible généré avec succès."

echo "Construction de l'image Docker Ansible..."
docker build -t ansible-container ./ansible
echo "Image Docker Ansible construite avec succès."

echo "Préparation à l'exécution du playbook Ansible..."
echo "-------------------------------------------------"
docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml

# Vérifie si la commande a échoué
if [ $? -ne 0 ]; then
    echo "La première tentative a échoué, tentative de relance..."
    # Tente d'exécuter la commande une seconde fois
    docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml
fi
echo "Playbook Ansible exécuté avec succès."