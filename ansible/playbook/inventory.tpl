[managers]
manager ansible_host=${manager_ip} ansible_user=ubuntu

[workers]
worker1 ansible_host=${worker1_ip} ansible_user=ubuntu
worker2 ansible_host=${worker2_ip} ansible_user=ubuntu

[defaults]
host_key_checking = False