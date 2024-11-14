# Experiment: Using Jetstream2 for Data Curation

Can I use Jetstream2 as a platform for data curation? Let's find out.

This repo includes terraform code and __ for provisioning a coder server on jetstream2. This includes:

- A private network with routing to the internet
- A storage?

## Credential

This assumes a file called `openrc.sh` with your OpenStack credentials for accessing Jetstream2.

## Terraform/OpenTofu

- Configure the `js2_project` variable in `variables.tf`
- You may need to adjust `image_id` for coder vm in `coder.tf`
- generate an ssh key and put the public key in `keys/coder.pub`
- 
```sh
cd terraform
source openrc.sh && tofu apply

# get the new OpenStack credential used by coder in config below:
tofu output coder_credential_secret
tofu output coder_credential_id
```

## Coder Server Config

... 

### TLS Installation on Coder Server

Follow steps here: https://docs.docker.com/engine/install/ubuntu/
configure dns-multi plugin:

```ini
#/etc/letsencrypt/dns-multi.ini
dns_multi_provider = designate
OS_AUTH_TYPE=v3applicationcredential
OS_AUTH_URL=https://js2.jetstream-cloud.org:5000/v3/
OS_IDENTITY_API_VERSION=3
OS_REGION_NAME="IU"
OS_INTERFACE=public
OS_APPLICATION_CREDENTIAL_ID="..."
OS_APPLICATION_CREDENTIAL_SECRET="..."
```

run with docker: 
```sh
docker run --rm -it \
 -v /etc/letsencrypt:/etc/letsencrypt \
 ghcr.io/alexzorin/certbot-dns-multi \
 certonly -a dns-multi --dns-multi-credentials /etc/letsencrypt/dns-multi.ini \
 -d "*.coder.oth240004.projects.jetstream-cloud.org" \
 -d "coder.oth240004.projects.jetstream-cloud.org" \
 -n --agree-tos -m serickson@ucsb.edu
```

Copy certs to `/etc/coder.d`:

```sh
mkdir /etc/coder.d
cp /etc/letsencrypt/live/coder.oth240004.projects.jetstream-cloud.org/fullchain.pem /etc/coder.d/
cp /etc/letsencrypt/live/coder.oth240004.projects.jetstream-cloud.org/privkey.pem   /etc/coder.d/
```

### Coder config and install

Config is in `/etc/coder.d/coder.env`:

```ini
CODER_ACCESS_URL=https://coder.oth240004.projects.jetstream-cloud.org
CODER_WILDCARD_ACCESS_URL=*.coder.oth240004.projects.jetstream-cloud.org
CODER_TLS_ADDRESS=0.0.0.0:443
CODER_HTTP_ADDRESS=0.0.0.0:80
CODER_REDIRECT_TO_ACCESS_URL=true
CODER_TLS_ENABLE=true
CODER_TLS_CERT_FILE=/etc/coder.d/fullchain.pem
CODER_TLS_KEY_FILE=/etc/coder.d/privkey.pem

# openstack config
OS_AUTH_TYPE=v3applicationcredential
OS_AUTH_URL=https://js2.jetstream-cloud.org:5000/v3/
OS_IDENTITY_API_VERSION=3
OS_REGION_NAME="IU"
OS_INTERFACE=public
OS_APPLICATION_CREDENTIAL_ID=FIXME
OS_APPLICATION_CREDENTIAL_SECRET=FIXME
```

Install coder:

```sh
curl -L https://coder.com/install.sh | sh
sudo chown coder:coder /etc/coder.d/*
sudo systemctl enable --now coder
```

Go to `https://coder.oth240004.projects.jetstream-cloud.org` and create admin account.

## Reference:

Another project using terraform on jetstream2:

https://gitlab.com/stack0/cacao-tf-jupyterhub