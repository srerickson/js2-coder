## Run Coder on JetStream2

[Coder](https://coder.com) is a self-hosted web service for managing cloud-based development environments. This repository
provides terraform configurations for running a Coder server on [JetStream2](https://jetstream-cloud.org/). 

## Usage

1. Download OpenStack and apply credentials from https://jetstream2.exosphere.app.
   1. `source XYZ-openrc.sh`
2. Customize variables in `server/main.tf`
3. Build the server: `cd server && terraform apply`
4. Once the server is created, you need to create admin user and get an API key



# notes

Start docker in coder

 docker run --rm -d \
     -p 127.0.0.1:8787:8787 \
     -v $(pwd):/root \
     -v $(echo $GIT_SSH_COMMAND | cut -d" " -f1):/tmp/coder/coder \
     -e DISABLE_AUTH=true \
     -e GIT_SSH_COMMAND='/tmp/coder/coder gitssh --' \
     -e CODER_AGENT_URL \
     -e CODER \
     -e CODER_AGENT_AUTH \
     -e CODER_AGENT_TOKEN \
     -e CODER_AGENT_URL \
     -e CODER_WORKSPACE_AGENT_NAME \
     -e CODER_WORKSPACE_NAME \
    rocker/tidyverse:latest