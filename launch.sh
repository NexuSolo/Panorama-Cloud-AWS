#!/bin/bash

cp myKey.pem ansible/playbook/myKey.pem
if [ $? -eq 0 ]; then
    echo "Étape 1: Clé SSH copiée avec succès."
else
    echo "Échec de l'Étape 1: La copie de la clé SSH a échoué."
    exit 1
fi

cp -r http/conf ansible/playbook/conf
if [ $? -eq 0 ]; then
    echo "Étape 2: Configuration HTTP copiée avec succès."
else
    echo "Échec de l'Étape 2: La copie de la configuration HTTP a échoué."
    exit 1
fi

cp -r db ansible/playbook/db
if [ $? -eq 0 ]; then
    echo "Étape 3: Base de données copiée avec succès."
else
    echo "Échec de l'Étape 3: La copie de la base de données a échoué."
    exit 1
fi

cp -r prometheus ansible/playbook/prometheus
if [ $? -eq 0 ]; then
    echo "Étape 4: Configuration Prometheus copiée avec succès."
else
    echo "Échec de l'Étape 4: La copie de la configuration Prometheus a échoué."
    exit 1
fi

export $(cat .env | xargs)
if [ $? -eq 0 ]; then
    echo "Étape 5: Variables d'environnement exportées avec succès."
else
    echo "Échec de l'Étape 5: L'exportation des variables d'environnement a échoué."
    exit 1
fi

# Assurez-vous de vérifier le succès de chaque commande Terraform de la même manière
echo "Préparation à l'exécution de Terraform..."
echo "-------------------------------------------"
echo "Étape 6: Initialisation de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform init
if [ $? -eq 0 ]; then
    echo "Terraform initialisé avec succès."
else
    echo "Échec de l'initialisation de Terraform."
    exit 1
fi


echo "Étape 7: Planification de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform plan
if [ $? -ne 0 ]; then
    echo "Échec de la planification de Terraform."
    exit 1
fi

echo "Étape 8: Application de Terraform..."
docker container run -it --rm -v $PWD/terraform:$PWD/terraform -w $PWD/terraform -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e TF_VAR_aws_instance_number=$AWS_INSTANCE_NUMBER -e TF_VAR_aws_aws_region=$AWS_REGION hashicorp/terraform apply -auto-approve > tmp/output.txt
if [ $? -ne 0 ]; then
    echo "Échec de l'application de Terraform."
    exit 1
else
    echo "Terraform appliqué avec succès."
fi

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
if [ $? -ne 0 ]; then
    echo "Échec de la construction de l'image Docker Ansible."
    exit 1
else
    echo "Image Docker Ansible construite avec succès."
fi

echo "Préparation à l'exécution du playbook Ansible..."
echo "-------------------------------------------------"
docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml
if [ $? -ne 0 ]; then
    echo "La première tentative a échoué, tentative de relance..."
    docker container run --rm -it ansible-container ansible-playbook -i inventory.ini playbook.yml
    if [ $? -ne 0 ]; then
        echo "Échec de l'exécution du playbook Ansible après deux tentatives."
        exit 1
    fi
else
    echo "Playbook Ansible exécuté avec succès."
fi

echo "Déploiement terminé avec succès."

echo "L'adresse IP de l'instance manager est : ${app_server_public_ip[0]}"

echo "Pour accéder à l'application de monitoring Prometheus, veuillez visiter http://${app_server_public_dns[0]}:9090 les identifiants sont : admin/admin"