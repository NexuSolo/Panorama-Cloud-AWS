FROM python:3.11

ENV ANSIBLE_VERSION 2.16

RUN pip3 install --upgrade pip; \
    pip3 install "ansible==${ANSIBLE_VERSION}"; \
    pip3 install ansible; \
    pip3 install boto3; \
    pip3 install boto

WORKDIR /playbooks

CMD ["ansible"]
