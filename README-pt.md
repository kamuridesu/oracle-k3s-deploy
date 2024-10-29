# oracle-k3s-deploy

Este repositório contém uma maneira fácil de configurar o k3s na OCI sem ter que gerenciar toda a configuração manualmente.

# Como funciona

O arquivo `setup.sh` é um script bash simples que clona dois repositórios, um contendo arquivos de configuração Terraform para criar os recursos e configurações necessários na OCI e outro contendo playbooks Ansible para configurar as VMs para o K3s.

# Configuração

Primeiro, você precisa obter algumas informações para o Terraform. Você precisa preencher essas variáveis:
- `TF_VAR_user` contém seu OCID de usuário;
- `TF_VAR_fingerprint` é o fingerprint do arquivo de chave usado como Chave de API para OCI;
- `TF_VAR_tenancy` é o OCID para sua tenancy na OCI;
- `TF_VAR_key_file` é seu arquivo de chave usado como Chave de API;
- `TF_VAR_compartment_id` geralmente é o mesmo que seu OCID de usuário, mas se você estiver usando outro compartimento, precisará alterá-lo;
- `TF_VAR_ssh_pub_key`: Sua chave pública SSH para acessar as VMs;
- `TF_VAR_public_ip_source`: lista de IPs públicos a partir dos quais você pode acessar o IP público das VMs K3s (em formato HCL, como: ["0.0.0.0/0"]);
- `TF_VAR_backend_password`: senha para seu Backend HTTP do Terraform;
- `TF_VAR_backend_username`: nome de usuário para seu Backend HTTP do Terraform;
- `TF_VAR_backend_url`: URL para seu Backend HTTP do Terraform.

O script também precisa de algum contexto para o deploy:

- `CERTBOT_EMAIL`: Email para o qual os certificados estão vinculados;
- `POSTGRES_PASSWORD`: Senha para o deployment do Postgres;
- `PRIVATE_KEY_PATH`: Caminho para sua chave privada (para acessar as VMs).

E o arquivo `domains` que contém uma lista de nomes de domínios que serão usados com o Certbot para gerar os certificados.

# Executando

Depois de configurar todas as configurações necessárias, basta executar o arquivo `setup.sh` e ele começará a provisionar seus recursos. Após o Terraform terminar, você verá uma saída com os IPs das suas máquinas recém-provisionadas. Copie o IP do balanceador de carga, configure seu DNS e pressione Enter (Return).

O script verificará se o IP do DNS corresponde ao IP do Load Balancer. Após cerca de 16 minutos, se não for encontrado, o script é abortado, caso contrário, ele continua com a configuração.

A configuração é feita com um playbook Ansible. Depois que ele terminar, tudo estará pronto para uso.

# Pós-configuração

Agora você precisa configurar seu haproxy manualmente adicionando o haproxy.cfg à VM. Caso esteja interessado, confira meu outro projeto: https://github.com/kamuridesu/ansible-haproxy.git

