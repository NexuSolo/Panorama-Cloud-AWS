
# Projet Panorama Cloud AWS

Projet pour la matière Panorama du cloud et déploiement AWS du M1 Efrei Dev Maneger FullStack

Ce projet a pour but d'automatiser le déploiement d'un projet web grace a plusieurs technologies :

- **Terraform** pour la création d'instance AWS
- **Ansible** pour l'installation des dépendances
- **Docker Swarm** pour la scalabilité de l'application
- **Prometheus** et **Grafana** pour le monitoring

## Installation

Cloner le projet 

```bash
git clone https://github.com/NexuSolo/Panorama-Cloud-AWS.git
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
sudo chmod +x launch.sh
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

## Problemès connus

## Autheurs

- [Nicolas Theau](https://github.com/NexuSolo)
- [Yanis Rozier](https://github.com/ConcombreDeMer)
- [Sébastien Zhou](https://github.com/Nebsu)
