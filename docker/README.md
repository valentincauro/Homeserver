_**Check the homepage for [the overview of docker applications](https://github.com/zilexa/Homeserver/blob/master/README.md#overview-of-applications-and-services) included in the compose file.**_

\
**Contents**
1. [Configure router & domain](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#configure-router--domain)
2. [The Docker Compose Guide](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#the-docker-compose-guide)
    - [Step 1: Prepare Docker](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-1---prepare-docker)
    - [Step 2: Prepare Compose](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-2---prepare-compose)
    - [Step 3: Run Compose](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-3---run-docker-compose)
    - [Step 4: Verification](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#step-4---verify)
    - [Common docker management tasks](https://github.com/zilexa/Homeserver/blob/master/docker/README.md#common-docker-management-tasks)


If you have an understanding of Docker containerization and docker-compose to set it up, realise the following:
- _Containers, Images and non-persistent Volumes are mostly expendable:_
  - You can delete them all (basically delete contents of /var/lib/docker), run docker-compose and it will pull all images online, create containers and use your persistent volumes ($HOME/docker/...): the applications should be in the same state as they were before deletion (unless you didn't make the required volumes persistent via compose).
- _This makes Docker the most simple, easy and fast way to deploy applications and maintain them._
  - Updating = pull new image, re-create container. Usually 1 command or 2 mouse-clicks. Deletion of a container/image does not delete its config/data. 

## Configure router & domain
1. Your router port forwarding:
    - At least the following ports should be forwarded to your servers local IP: **TCP port 443** to access some services via public internet (via HTTPS tls1.2 secured connection, taken care of by Caddy, the most modern & easiest to configure reverse proxy), **UDP port 51820** for Wireguard-VPN access via PiVPN, **TCP and UDP port 22000** for syncing devices via Syncthing.
    - other containers, applications or services including SSH will **only be accessible via VPN**.
2. **DynDNS**: a url that links to your home IP, even when your ISP changes it. Most routers allow you to enable this and provide you with a URL. Otherwise, google how to do that. 
3. **Acquire your own domain (mydomain.com) and link it with an ALIAS to that dynamic-dns url**. I recommend to buy your domain via porkbun.com or godaddy.com. This is a requirement to be able to access your files (FileRun & OnlyOffice), sync your browser between devices (Firefox-Sync), use the best password manager (Bitwarden) and manage synced PCs (Syncthing) as those services need to be exposed online. 
    - The connection will only allow TLS/HTTPS encrypted connections, meaning your information is protected in transit. 
 4. At the configuration panel of your domain provider, create: 
    - an **ALIAS** dns record to your dyndns (`ALIAS - mydomain.com - mydyndnsurl`). 
    - an **ALIAS** dns record from www to your domain (`ALIAS - www.mydomain.com - mydomain.com`).
    - a **CNAME** dns record registering subdomains to your domain for each subdomain in your docker-compose.yml (`CNAME - subdomain.domain.com - mydomain.com`).  
5. If you want **email notifications** (recommended), create a feee account with an SMTP provider. I have bad experience with sendgrid.com, very good experience with smtp2go.com, it explains very well how to configure your domain to make sure emails do not end up in your Gmail/outlook.com junk folder.  

&nbsp;
## The Docker Compose Guide 
### Step 1 - Prepare Docker
A prep script, containing lots of info I gathered/learned via trial&error, can save you a lot of time. 
Go through the script and execute what you need manually, or download and execute it: 
```
cd Downloads
wget https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/prepare_server_docker.sh
bash prepare_server_docker.sh
```
What the script will do for you, automatically: 
  - Set permissions (root only) to your $HOME/docker folder and create specific files and folders required for Filerun to run. 
  - If you will not use Filerun/Elasticsearch, remove its folder from the docker folder when done. 
  - Install docker via repository (auto-update) and related dependencies. 
  - Get the docker-compose.yml file and its .env file from this repository. 

What you have to do yourself during execution: 
1. Read the questions, follow the install wizards of PiVPN, Netdata and allow lm-sensors to scan & configure your systems diagnostic sensors: 
    - PiVPN: choose Wireguard and when asked which DNS server you want, choose custom and fill in your own server LAN IP if you plan on running AdGuard Home/Unbound. Otherwise select Quad9 or similar. 
    - lm-sensors: just select yes everywhere and let it do its thing. Don't mind the warnings here. 
    - Netdata: just follow the wizard. 
    - NFSv4.2: read more about it here: https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)

#### Step 2 - Prepare Compose
Notice the script has placed 2 files in $HOME/docker: `docker-compose.yml` and (hidden) `.env`. 
Notice this folder and its contents are read-only, you need elevated root rights to edit the files. 
Modify docker-compose.yml to your needs and understand the (mostly unique for your setup) variables that are expected in your.env file.   
Things you need to take care of:
- .env file: set the env variables in the .env file, generate the required secret tokens with the given command.
- docker-compose.yml: Change the subdomains (for example: `files.$DOMAIN`) to your liking.
- docker-compose.yml: Make sure the volume mappings are correct for those that link to the Users or TV folders. 
- if you remove certain applications, at the bottom also remove unneccary networks.
- notice the commands at the top of the compose file, for your convenience. 
 
#### Step 3 - Run Docker Compose
`cd docker` (when you open terminal, you should already be in $HOME).
Check for errors: `docker-compose -f docker-compose.yml config` or if you are not in that folder (`cd docker`): `docker-compose -f $HOME/docker/docker-compose.yml config` using -f to point to the location of your config files. 

Before running docker-compose, make sure: 
- all app-specific requirements are taken care of. The script from the 
- the .env file is complete and correct.
- the docker-compose.yml file is correct. 
- Open a terminal (CTRL+ALT+T or Budgie>Tilix). **Do not prefix with sudo**. `docker-compose -f $HOME/docker/docker-compose.yml up -d`
- **Warning: if you do prefix with sudo, everything will be created in the root dir instead of the $HOME/docker dir, the container-specific persistent volumes will be there as well and you will run into permission issues. Plus none of the app-specific preperations done by the script will have affect as they are done in $HOME/docker/. Also the specific docker subvolume is not used and not backupped.**

All images will be downloaded, containers will be build and everything will start running. 
Run again in case you ran into time-outs, this can happen, as a server hosting the image might be temp down. Just delete the containers, images and volumes in Portainer and re-run the command. 

#### Step 4 - Verify
5. Go to portainer: yourserverip:9000 login and go to containers. Everything should be green. 
6. To update an application in the future, click that container, hit `recreate` and check `pull new image`. 

## Common Docker management tasks
**Docker Management** 
Via Portainer, you can easily access each of your app by clicking on the ports. 
Go ahead and configure each of your applications.
I recommend configuring a dns record in your router OR use AdGuard Home > Settings > DNS rewrite to create easy urls like my.server to access all your services via my.server:portnumber and configure Organizr, so that you can access ALL services within your LAN and via VPN via 1 url. 

**Check status of your apps/containers**
A. Open Portainer (your.server.lan.IP:9000), click containers, green = OK.\
B. Open a container to investigate, click "Inspect" and make sure "dead=false". Go back, click Log to check logfile.\
C. If needed, you can even access the terminal of the container and check files/logs directly. But an easier way is to go to those files in $HOME/docker/yourcontainer. Only persistent volumes (mapped via docker-compose.yml) are there. Expendable data (containers, volumes, images) is in/var/lib/docker/.  

**Cleanup docker**
To remove unused containers (be careful, this means any stopped container) and dangling images, non-persistent volumes: 
 `sudo docker system prune --all --volumes --force`
 Note this will be done automatically via the scheduled maintenance (next guide). 
 
**Update apps**
In Portainer, click on a container, then select _Recreate_ and check the box to re-download the image. 
The latest image will be downloaded and a new container will be created with it. 
It will still use your persistent volume mappings: your configuration and persistent data remains. Just like a normal application update. 
Note: Monitorr can be used to be notified of updates + update automatically (by default don't do that for all services).  

**Issues:** 
Permission issues can be solved with the chown and chmod commands.
For example Filerun needs you to own the very root of the user folder (/mnt/pool/Users), not root. 
