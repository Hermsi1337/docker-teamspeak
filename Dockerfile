FROM    	frolvlad/alpine-glibc:alpine-3.10

LABEL   	maintainer "https://github.com/hermsi1337"

ARG			TS_SERVER_VER="3.5.0"
ENV			TS_SERVER_VER="${TS_SERVER_VER}" \
			TS_USER="teamspeak" \
			TS_HOME="/teamspeak" \
			TS3_MARIADB_PORT="3306" \
			DEFAULT_VOICE_PORT="9987" \
			FILE_TRANSFER_PORT="30033" \
			QUERY_PORT="10011" \
			TS3SERVER_LICENSE="accept"

ADD			entrypoint.sh /entrypoint.sh
WORKDIR		${TS_HOME}

RUN			set -x \
    		&& apk update \
			&& apk upgrade \
    		&& apk add ca-certificates wget openssl bash mysql-client \
    		&& update-ca-certificates \
    		&& apk --virtual .build-dependencies add w3m bzip2 \
			&& addgroup -S \
					-g 503 \
    		   		$TS_USER \
    		&& adduser -S \
    		       	-u 503 \
    		       	-G $TS_USER \
    		       	-D \
					$TS_USER \
			&& wget https://files.teamspeak-services.com/releases/server/${TS_SERVER_VER}/teamspeak3-server_linux_amd64-${TS_SERVER_VER}.tar.bz2 -O /tmp/teamspeak.tar.bz2 \
  			&& tar jxf /tmp/teamspeak.tar.bz2 -C /tmp \
  			&& mv /tmp/teamspeak3-server_*/* ${TS_HOME} \
    		&& rm /tmp/teamspeak.tar.bz2 \
    		&& apk del .build-dependencies \
    		&& rm -rf /tmp/* \
			&& cp "$(pwd)/redist/libmariadb.so.2" $(pwd) \
			&& chown -R ${TS_USER}:${TS_USER} ${TS_HOME} \
			&& chmod +x /entrypoint.sh

USER		${TS_USER}

EXPOSE 		9987/udp 10011 30033

VOLUME 		["${TS_HOME}"]

ENTRYPOINT	["/entrypoint.sh"]
