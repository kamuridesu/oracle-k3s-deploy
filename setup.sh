#! /bin/bash

tf () {
    tofu $@ && notify-send -a Terraform Terraform OK && return 0 || notify-send -a Terraform Fail && return 1
}

set -a
source vars.env
set +a

VARS=(TF_VAR_user TF_VAR_fingerprint TF_VAR_tenancy TF_VAR_key_file TF_VAR_compartment_id TF_VAR_ssh_pub_key TF_VAR_public_ip_source TF_VAR_backend_password TF_VAR_backend_username TF_VAR_backend_url POSTGRES_PASSWORD PRIVATE_KEY_PATH)

for var in ${VARS[@]}; do
    if [ -z "${!var}" ]; then
        echo "Variable $var is not set"
        exit 1
    fi
done

if [[ ! -f "hosts" ]]; then
    echo "Hosts file not found"
    exit 1
fi

git clone https://github.com/kamuridesu/oracle-k3s-terraform.git terraform
git clone https://github.com/kamuridesu/ansible-oracle-k3s.git ansible

cd terraform
tf init
tf apply

VM_IP_ADDR=$(tf output -json)
set -a
CP_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.k3s_public_ip.value["k3s-cp"]')
WORKER_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.k3s_public_ip.value["k3s-node"]')
LB_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.lb_public_ip.value["load-balancer"]')
set +a

read -p "Setup your DNS to point to the Load Balancer IP: $LB_IP and press [Enter]"
read -p "Enter your DNS name: " DNS_NAME

for i in {1..50}; do  # total wait: 500s (5m)
    echo "Checking DNS..."
    LB_IP_DNS=$(dig +short $DNS_NAME)
    if [ "$LB_IP_DNS" == "$LB_IP" ]; then
        echo "DNS is pointing to the Load Balancer IP"
        break
    else
        echo "DNS is not pointing to the Load Balancer IP. Retrying in 10 seconds..."
        sleep 10
    fi
done

cd ../ansible

cat ../hosts.example | envsubst > inventory/hosts

ansible-playbook -i inventory/hosts --private-key ${PRIVATE_KEY_PATH} playbook.yml

cd ..
