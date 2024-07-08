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

## Reference:

Another project using terraform on jetstream2:

https://gitlab.com/stack0/cacao-tf-jupyterhub