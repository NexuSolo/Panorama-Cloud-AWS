FROM python:3.11

RUN apt-get update && \
    apt-get install -y openssh-client && \
    apt-get clean

RUN pip install --upgrade pip

RUN pip install ansible

RUN pip install boto3 boto jsondiff

RUN ansible-galaxy collection install community.grafana

RUN ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

WORKDIR /playbooks

COPY playbook/* ./

RUN chmod 400 myKey.pem

# CMD ["ansible-playbook", "-i", "inventory.ini", "playbook.yml"]
