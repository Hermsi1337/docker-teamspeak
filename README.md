## TeamSpeak3 dockerized

An image to run a TeamSpeak3 server in a docker container based on alpine. It's also possible to connect an external database.

## Regular builds, automagically
[![Build Status](https://travis-ci.com/Hermsi1337/docker-teamspeak.svg?branch=master)](https://travis-ci.com/Hermsi1337/docker-teamspeak) .  
Thanks to [Travis-CI](https://travis-ci.com/) this image is pushed weekly and creates new [tags](https://hub.docker.com/r/hermsi/alpine-teamspeak/tags/) if there are new versions available.

### Fast and easy way (no persisent storage):

That is how to run the container without a persisent storage. I only recommend this way for testing:

```bash
docker run -d --name teamspeak -p 9987:9987/udp -p 30033:30033 -p 10011:10011 hermsi/teamspeak
```

### Professional way (persisent storage):

I'd recommend to use docker-compose (see next paragraph). If you don't like docker-compose but you want to keep your data when restarting the container, run it as follows:

#### Without external database

1. Create all needed directories and set correct permissions
   ```bash
   export TS_VOLUME="/var/storage/docker/volumes/teamspeak" \
   && mkdir -p "${TS_VOLUME}" \
   && chown -R 503:503 "${TS_VOLUME}"
   ```
2. Run your TS3 container
   ```bash
   docker run -d --restart=always --name teamspeak \
     -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
     -v ${TS_VOLUME}:/teamspeak \
     hermsi/teamspeak
   ```
   
#### Using external database

1. Create all needed directories and set correct permissions
   ```bash
   export TS_VOLUME="/var/storage/docker/volumes/teamspeak" \
   && mkdir -p "${TS_VOLUME}/teamspeak" \
   && mkdir -p "${TS_VOLUME}/mysql"
   ```
2. Create a network for your teamspeak3 and mariadb container
   ```bash
   docker network create my_teamspeak
   ```
3. Run your MariaDB
   ```bash
   docker run -d --restart=always --name teamspeak_database --net my_teamspeak \
     -v ${TS_VOLUME}/mysql:/var/lib/mysql \
     -e MYSQL_ROOT_PASSWORD=CHANGEME \
     -e MYSQL_DATABASE=teamspeak \
     -e MYSQL_USER=teamspeak \
     -e MYSQL_PASSWORD=CHANGEME \
     mariadb
   ```
4. Run your TS3 container
   ```bash
   docker run -d --restart=always --name teamspeak --net my_teamspeak \
     -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
     -v ${TS_VOLUME}/teamspeak:/teamspeak \
     -e TS3_MARIADB_DB=teamspeak \
     -e TS3_MARIADB_USER=teamspeak \
     -e TS3_MARIADB_PASS=CHANGEME \
     -e TS3_MARIADB_HOST=teamspeak_database \
     -e TS3_MARIADB_PORT=3306 \
     hermsi/teamspeak
   ```
   
### More professional way (docker-compose with local-persist driver):

To make your storage persisent using the latest v3 of docker-compose, I really recommend to use local-persist as follows.

1. Install the local-persist driver. [See here for reference](https://github.com/CWSpear/local-persist).

   ```bash
   curl -fsSL https://raw.githubusercontent.com/CWSpear/local-persist/master/scripts/install.sh | sudo bash
   ```
   
2. Create docker-compose.yml file. See also [here](https://github.com/Hermsi1337/docker-teamspeak/blob/master/docker-compose.yml).

   ```yml
   version: '3'

   volumes:
     teamspeak-data:
        driver: local-persist
        driver_opts:
          mountpoint: ${CONTAINERVOLUME}/teamspeak
     teamspeak-db-data:
        driver: local-persist
        driver_opts:
          mountpoint: ${CONTAINERVOLUME}/var/lib/mysql

   services:

     database:
       image: mariadb
       volumes:
         - teamspeak-db-data:/var/lib/mysql
       environment:
         - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
         - MYSQL_DATABASE=${MYSQL_DATABASE}
         - MYSQL_USER=${MYSQL_USER}
         - MYSQL_PASSWORD=${MYSQL_PASSWORD}

     application:
       image: hermsi/teamspeak
       depends_on:
         - database
       environment:
         - TS3_MARIADB_DB=${MYSQL_DATABASE}
         - TS3_MARIADB_USER=${MYSQL_USER}
         - TS3_MARIADB_PASS=${MYSQL_PASSWORD}
         - TS3_MARIADB_HOST=database
         - TS3_MARIADB_PORT=3306
       volumes:
         - teamspeak-data:/teamspeak     
       ports:
         - 9987:9987/udp 
         - 30033:30033 
         - 10011:10011
   ```
   
3. Create your related .env-file. Feel free to use [this boilerplate](https://github.com/Hermsi1337/docker-teamspeak/blob/master/.env_)

   ```bash
   # Docker-Compose
   ## project-name
   COMPOSE_PROJECT_NAME=My_Teamspeak
   ## Volumedir
   CONTAINERVOLUME=/var/storage/docker/volumes/teamspeak

   # Database
   ## Username
   MYSQL_USER=teamspeak
   ## Root password
   MYSQL_ROOT_PASSWORD=CHANGEME_HARD
   ## Database
   MYSQL_DATABASE=teamspeak
   ## User Password
   MYSQL_PASSWORD=CHANGEME
   ```
   
4. Run your server using docker-compose

   ```bash
   docker-compose up -d
   ```
