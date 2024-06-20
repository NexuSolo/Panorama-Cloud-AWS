#!/bin/bash
# Launch ansible docker
docker image build -t ansible:2.16 . 

docker container run --rm -v $PWD:/playbooks ansible:2.16 ansible-playbook -i inventory.ini playbook.yml