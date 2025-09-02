# install mailcow on RHEL9
### Install dependences
```bash 
dnf install -y git openssl curl gawk coreutils grep jq
```
### Install Docker
```bash 
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
```
### Install Docker Compose 
```bash 
dnf update
dnf install -y docker-compose-plugin 
```
 #### Note: For the plugin version, the command is docker compose (without a hyphen).

 ### Installing mailcow
```bash 
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
```
#### Generate the configuration file:
#### backup generate file
```bash 
mv generate_config.sh  generate_config.sh.bckp
```
#### create a new generate file
#### use this file https://github.com/ConsLeGrand/install-mailcow-on-rhel9/generate_config.sh
```bash 
curl -o generate_config.sh https://github.com/ConsLeGrand/install-mailcow-on-rhel9/generate_config.sh
vim generate_config.sh
chmod +x generate_config.sh
```
#### Adjust the configuration if necessary:

```bash 
vim  mailcow.conf
```

### Starting mailcow
```bash 
docker compose pull
docker compose up -d
```
You can now access https://${MAILCOW_HOSTNAME}/admin using the default credentials admin and the password moohoo.
