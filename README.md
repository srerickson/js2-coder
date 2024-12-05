## Run Coder on JetStream2

[Coder](https://coder.com) is a self-hosted web service for managing cloud-based development environments. This repository
provides terraform configurations for running a Coder server on [JetStream2](https://jetstream-cloud.org/). 

## Usage

1. Download OpenStack and apply credentials from https://jetstream2.exosphere.app.
   1. `source XYZ-openrc.sh`
2. Customize variables in `server/main.tf`
3. Build the server: `cd server && terraform apply`
4. Once the server is created, you need to create admin user and get an API key