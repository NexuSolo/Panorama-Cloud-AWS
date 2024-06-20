FROM python:3.11

ENV ANSIBLE_VERSION 2.16

RUN apt-get update && \
    apt-get install -y openssh-client && \
    apt-get clean

RUN pip install --upgrade pip

RUN pip install "ansible==${ANSIBLE_VERSION}"

RUN pip install boto3 boto;

# Générer une paire de clés SSH sans passphrase
RUN ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

WORKDIR /playbooks

# Copier les fichiers de playbook dans le conteneur
COPY playbook/* ./

# CMD ["ansible"]
