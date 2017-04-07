FROM  ubuntu:latest

ENV   TS_USER=teamspeak \
      TS_HOME=/teamspeak

RUN	apt-get update && apt-get install -y w3m bzip2 w3m wget mysql-common \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN	groupadd -r $TS_USER \
    && useradd -r -m \
    	-g $TS_USER \
        -d $TS_HOME \
        $TS_USER

WORKDIR ${TS_HOME}

RUN	TS_SERVER_VER="$(w3m -dump https://www.teamspeak.com/downloads | grep -m 1 'Server 64-bit ' | awk '{print $NF}')" \
	&& wget http://dl.4players.de/ts/releases/${TS_SERVER_VER}/teamspeak3-server_linux_amd64-${TS_SERVER_VER}.tar.bz2 -O /tmp/teamspeak.tar.bz2 \
  	&& tar jxf /tmp/teamspeak.tar.bz2 -C /opt \
  	&& mv /opt/teamspeak3-server_*/* ${TS_HOME} \
  	&& rm /tmp/teamspeak.tar.bz2 \
  	&& apt-get purge -y bzip2 w3m wget \
  	&& apt-get autoremove -y \
  	&& rm -rf /var/lib/apt/lists/*

RUN  cp "$(pwd)/redist/libmariadb.so.2" $(pwd)

ADD entrypoint.sh ${TS_HOME}/entrypoint.sh

RUN chown -R ${TS_USER}:${TS_USER} ${TS_HOME} && chmod +x entrypoint.sh

USER  ${TS_USER}

EXPOSE 9987/udp
EXPOSE 10011
EXPOSE 30033

ENTRYPOINT ["./entrypoint.sh"]
