
# Projet Panorama Cloud AWS

Projet pour la matière Panorama du cloud et déploiement AWS du M1 Efrei Dev Maneger FullStack

Ce projet a pour but d'automatiser le déploiement d'un projet web grace a plusieurs technologies :

- **Terraform** pour la création d'instance AWS
- **Ansible** pour l'installation des dépendances
- **Docker Swarm** pour la scalabilité de l'application
- **Prometheus** et **Grafana** pour le monitoring

## Prérequis

- [Docker](https://docs.docker.com/engine/install/ubuntu/)

## Installation

Cloner le projet 

```bash
git clone https://github.com/NexuSolo/Panorama-Cloud-AWS.git
cd Panorama-Cloud-AWS
```

Configurer les variables d'environnement (voir section variables d'environnement)

```bash
nano .env
```

Ajouter le fichier myKey.pem a la racine du projet et donner les droits de lecture uniquement à l'administrateur

```bash
cp source/myKey.pem ./myKey.pem
sudo chmod 400 myKey.pem
```

Ajouter les droits d'execution a launch.sh et clear.sh

```bash
sudo chmod +x launch.sh clear.sh
```

Lancer le script launch.sh

```bash
sudo ./launch.sh
```

Pour supprimer les instances lancer le script clear.sh

```bash
sudo ./clear.sh
```

## Variables d'Environment

Pour lancer le projet, vous aurez besoin de définir les variables d'environnement suivantes dans votre fichier .env

`AWS_ACCESS_KEY_ID` Client ID de votre compte AWS 

`AWS_SECRET_ACCESS_KEY` Client Secret de votre compte AWS

`AWS_INSTANCE_NUMBER` Nombre d'instance a lancer

`AWS_REGION` Region AWS

## Fonctionnalité

- Déploiement Automatisé sur AWS : Utilise Terraform pour créer des instances AWS, configurées via le script launch.sh et le fichier de configuration Terraform main.tf.

- Installation Automatisée des dépendances : Utilise Ansible pour installer les dépendances du projet sur les instances AWS. Le playbook ansible/playbook/playbook.yml est utilisé pour installer les dépendances.

- Scalabilité de l'application : Utilise Docker Swarm pour permettre la scalabilité de l'application. Le docker-compose se trouve dans ansible/playbook/docker-compose.yml.

- Monitoring : Utilise Prometheus et Grafana pour le monitoring de l'application. Les fichiers de configuration se trouvent dans /prometheus. Un dashboard est automatiquement créer dans Grafana apres l'installation via le playbook ansible.

- Serveur Web : L'application web est un serveur web node.js qui affiche un message de bienvenue. Le code source se trouve dans /node. Il y a aussi le possibilité d'acceder a la liste des utilisateur postgres via l'url /test.

- Base de données : Utilise une base de données PostgreSQL pour stocker les utilisateurs. Le fichier de configuration se trouve dans /db.

- Nginx : Utilise Nginx pour rediriger les requêtes vers le serveur web node. Le fichier de configuration se trouve dans /http.

- Clean : Un script clear.sh est disponible pour supprimer les instances AWS.

## Problemès connus

Message d'erreur qui apparait lors du du terraform apply :

```bash
aws_security_group.app_server_sg: Creation complete after 2s [id=sg-0dbe2b78059188305]
aws_instance.app_server[1]: Creating...
aws_instance.app_server[2]: Creating...
aws_instance.app_server[0]: Creating...
╷
│ Error: creating EC2 Instance: InvalidAMIID.NotFound: The image id '[ami-00ac45f3035ff009e]' does not exist
│       status code: 400, request id: d05f4214-0a7b-4570-93b9-3a262ae80927
│
│   with aws_instance.app_server[2],
│   on main.tf line 16, in resource "aws_instance" "app_server":
│   16: resource "aws_instance" "app_server" {
│
```

Vérifier la region AWS dans le .env. Attention si vous changer la region il faut changer l'ami dans le terraform/main.tf

-------------------

Message d'erreur qui apparait lors du chargement de la partie Ansible :

```bash :
=> ERROR [1/9] FROM docker.io/library/python:3.11@sha256:3293c1c51267035cc7dbde027740c9b03affb5e8cff6220d30b7c970e39b1406
```

Le pull de l'image python:3.11 peut ne pas fonctionner correctement, dans ce cas il est possible de la télécharger manuellement avec la commande suivante puis relancer le script launch.sh

```bash
docker pull python:3.11
```

-------------------

Message d'erreur qui apparait lors de l'execution du playbook Ansible :

```bash

Préparation à l'exécution du playbook Ansible...
-------------------------------------------------

PLAY [Setup Docker Swarm Cluster] ********************************************************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************************************************************************
fatal: [manager]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host ec2-35-180-31-175.eu-west-3.compute.amazonaws.com port 22: Connection refused", "unreachable": true}

PLAY RECAP *******************************************************************************************************************************************************************************************************
manager                    : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0
```

Il est possible que le playbook Ansible ne puisse pas se connecter a l'instance AWS, dans ce cas relancer le script launch.sh

```bash
sudo ./launch.sh
```

## Autheurs

- [Nicolas Theau](https://github.com/NexuSolo)
- [Yanis Rozier](https://github.com/ConcombreDeMer)
- [Sébastien Zhou](https://github.com/Nebsu)
