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

if [ ! -f domains ]; then
    echo "File 'domains' not found. Please create a file 'domains' with the domain name you want to use."
    exit 1
fi

DOMAINS=$(cat domains)
FIRST_DOMAIN=$(echo "${DOMAINS}" | head -n 1)
COMMA_SEPARATED_DOMAINS=$(echo "${DOMAINS}" | tr '\n' ',' | sed 's/,$//')

git clone https://github.com/kamuridesu/oracle-k3s-terraform.git terraform 2>/dev/null || (cd terraform && git pull)
git clone https://github.com/kamuridesu/ansible-oracle-k3s.git ansible 2>/dev/null || (cd ansible && git pull)

cd terraform

# check if the backend is already initialized
if [ -f .terraform/terraform.tfstate ]; then
    echo "Backend already initialized. Skipping..."
else
    tf init
fi

tf apply

VM_IP_ADDR=$(tf output -json)
set -a
CP_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.k3s_public_ip.value["k3s-cp"]')
WORKER_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.k3s_public_ip.value["k3s-node"]')
LB_IP=$(echo -n "${VM_IP_ADDR}" | jq -r '.lb_public_ip.value["load-balancer"]')
set +a

LB_IP_DNS=$(dig +short $FIRST_DOMAIN)
if [ "$LB_IP_DNS" != "$LB_IP" ]; then
    read -p "Setup your DNS '$FIRST_DOMAIN' to point to the Load Balancer IP: '$LB_IP' and press [Enter]"
    for i in {1..50}; do  # total wait: 1000s (~16m)
        echo "Checking DNS..."
        LB_IP_DNS=$(dig +short $FIRST_DOMAIN)
        if [ "$LB_IP_DNS" == "$LB_IP" ]; then
            echo "DNS is pointing to the Load Balancer IP"
            break
        else
            echo "DNS is not pointing to the Load Balancer IP. Retrying in 10 seconds..."
            sleep 20
        fi
    done

fi

if [ "$LB_IP_DNS" != "$LB_IP" ]; then
    echo "Could not verify DNS. Exiting..."
    exit 1
fi

cd ../ansible

cat ../hosts | envsubst > inventory/hosts

ansible-playbook -i inventory/hosts --private-key ${PRIVATE_KEY_PATH} -e "domains=$COMMA_SEPARATED_DOMAINS user_email=$CERTBOT_EMAIL" playbook.yml

cd ..
