FROM	alpine:latest

ENV	TS_USER=teamspeak \
	TS_HOME=/teamspeak

# Get some stuff in order to work properly
RUN	set -x \
    	&& apk update \
    	&& apk --no-cache add ca-certificates wget openssl bash \
    	&& update-ca-certificates \
    	&& apk --no-cache --virtual .build-dependencies add w3m bzip2

# Install su-exec for easy step-down from root
RUN	set -x \
	&& apk --no-cache add su-exec

# Install the GNU C library and set locales
ENV	GLIBC_VERSION=2.25-r0
RUN	set -x \
	&& wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
	&& wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" \
	&& wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" \
	&& wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk" \
	&& apk --no-cache add glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk \
    	&& /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true \
    	&& echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh \
    	&& rm /etc/apk/keys/sgerrand.rsa.pub /root/.wget-hsts
ENV 	LANG=C.UTF-8

RUN 	addgroup -S $TS_USER \
    	&& adduser -S \
    		-G $TS_USER \
    		-D \
    		$TS_USER

WORKDIR	${TS_HOME}

# Get teamspeak package
RUN	TS_SERVER_VER="$(w3m -dump https://www.teamspeak.com/downloads | grep -m 1 'Server 64-bit ' | awk '{print $NF}')" \
	&& wget http://dl.4players.de/ts/releases/${TS_SERVER_VER}/teamspeak3-server_linux_amd64-${TS_SERVER_VER}.tar.bz2 -O /tmp/teamspeak.tar.bz2 \
  	&& tar jxf /tmp/teamspeak.tar.bz2 -C /tmp \
  	&& mv /tmp/teamspeak3-server_*/* ${TS_HOME}

# Clean up
RUN	set -x \
    	&& rm /tmp/teamspeak.tar.bz2 \
    	&& apk del .build-dependencies \
    	&& rm -rf /tmp/*

RUN 	cp "$(pwd)/redist/libmariadb.so.2" $(pwd)

ADD 	entrypoint.sh ${TS_HOME}/entrypoint.sh

RUN 	chown -R ${TS_USER}:${TS_USER} ${TS_HOME} && chmod +x entrypoint.sh

USER  	${TS_USER}

EXPOSE 	9987/udp
EXPOSE 	10011
EXPOSE 	30033

ENTRYPOINT ["./entrypoint.sh"]
