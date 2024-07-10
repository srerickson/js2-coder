# Using Jetstream2 for Data Curation

Can we use the NSF-funded research computing cloud infrastructure, Jetstream2, 
as a platform for data curation? Let's find out.

This includes terraform code and __ for provisioning infrastructure 
on jetstream2. This includes:

- A private network with routing to the internet
- A storage pool 

## terraform

```sh
cd terraform
source openrc.sh && tofu apply
```

## certs

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

## Reference:

Another project using terraform on jetstream2:

https://gitlab.com/stack0/cacao-tf-jupyterhub


ß