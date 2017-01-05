FROM helterscelter/base:oracle-java8

MAINTAINER Helter Scelter


ENV ZK_HOME /opt/zookeeper
ENV ZK_CONFIGDIR ${ZK_HOME}/conf
ENV ZK_DATADIR /zookeeper/data
ENV ZK_DATALOGDIR /zookeeper/log


ENV ZOOKEEPER_VERSION 3.4.9

#Download Zookeeper
#Verify download
RUN wget --continue --timeout=10  --progress=dot:mega $( wget -q -O -  https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred|rtrimstr("/")')/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz && \
	wget -q https://www.apache.org/dist/zookeeper/KEYS && \
	wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc && \
	wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 && \
	md5sum -c zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 && \
	gpg --import KEYS && \
	gpg --verify zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc && \
	tar -xzf zookeeper-${ZOOKEEPER_VERSION}.tar.gz -C /opt && \
	ln -s /opt/zookeeper-${ZOOKEEPER_VERSION} ${ZK_HOME} && \
	rm  zookeeper-${ZOOKEEPER_VERSION}.tar.gz*

# create the zookeeper user, home, group and directories
RUN groupadd zookeeper; \
    useradd --gid zookeeper --home-dir /home/zookeeper --create-home --shell /bin/bash zookeeper; \
    mkdir -p ${ZK_DATADIR} ${ZK_DATALOGDIR} ${ZK_CONFIGDIR}; \
    chown -RL zookeeper:zookeeper ${ZK_CONFIGDIR} ${ZK_DATADIR} ${ZK_DATALOGDIR}



# get docker-gen https://github.com/jwilder/docker-gen
# so we can monitor for additional zookeeper instances
ENV DOCKER_GEN_VERSION 0.7.3
ENV DOCKER_HOST unix:///var/run/docker.sock

RUN wget -O- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin


# copy all templates to the zookeeper config location
ADD conf ${ZK_CONFIGDIR}

# copy dockergen templates and 
# add the zookeeper supervisord template to the system supervisor config location
ADD etc /etc


# process the docker-gen config 
RUN /usr/bin/template.sh /etc/dockergen/zookeeper.dockergen.template /etc/dockergen/zookeeper.dockergen ${ZK_HOME}


EXPOSE 2181 2888 3888

VOLUME [ ${ZK_DATALOGDIR}, ${ZK_DATADIR}, ${ZK_CONFIGDIR} ]

CMD ["supervisord","-c","/etc/supervisor/supervisord.conf"]
