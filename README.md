# oracle-k3s-deploy

This repositories is a painless-way to setup k3s on OCI without having to manage all the configuration manually.

This README is also available in Brazilian Portuguese, check out: [README-pt.md](README-pt.md)

# How it works

The file `setup.sh` is a simple bash script that clones two repositories, one containing Terraform configuration files for creating the necessary resources and configurations on OCI and another containing Ansible playbooks to configure the VMs for K3s.

# Setting up

First you need to get some information for Terraform. You need to fill those variables:
- `TF_VAR_user` contains your user ocid;
- `TF_VAR_fingerprint` is the fingerprint of the keyfile used as API Key for OCI;
- `TF_VAR_tenancy` is the ocid for your OCI tenancy;
- `TF_VAR_key_file` is your keyfile used as API Key;
- `TF_VAR_compartment_id` generally is the same as your user ocid, but if you're using another compartment you need to change it;
- `TF_VAR_ssh_pub_key`: Your ssh public key to ssh into the VMs;
- `TF_VAR_public_ip_source`: list of public IPs from which you can access the public IP of the K3s VMs (in HCL format, like: ["0.0.0.0/0"])
- `TF_VAR_backend_password`: password for your Terraform HTTP Backend
- `TF_VAR_backend_username`: username for your Terraform HTTP Backend
- `TF_VAR_backend_url`: URL for your Terraform HTTP Backend

The script also needs some context for the deploy:

- `CERTBOT_EMAIL`: Email for which the certificates are linked
- `POSTGRES_PASSWORD`: Password for the postgres deployment
- `PRIVATE_KEY_PATH`: Path for your private key (to access the VMs)

And the file `domains` which contains a list of domains names that'll be used with Certbot to generate the certificates.

# Running

After setting up all the necessary configuration, just run the file `setup.sh` and it'll start to provision your resources. After Terraform finishes, you will see a output with the IPs of your newly provisioned machines. Copy the IP of the load balancer, setup your DNS and press Enter (Return). 

The script will check whether the DNS IP matches your Load Balancer IP. After about 16 minutes, if not found the script is aborted, else it continues with the configuration.

The configuration is done with an Ansible playbook. After it finishes it's all ready to go.

# Post configuration

Now you need to setup your haproxy manually adding the haproxy.cfg to the VM. In case you're interested, check my other project: https://github.com/kamuridesu/ansible-haproxy.git
