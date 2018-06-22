FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends curl \
        wget \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# Docker Repo
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Singularity Repo
RUN apt-key adv --recv-keys --keyserver hkp://pool.sks-keyservers.net:80 0xA5D32F012649A5A9
RUN wget -O- http://neuro.debian.net/lists/xenial.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list

# Install
RUN apt-get update && apt-get install -y singularity-container docker-ce
RUN singularity --version

WORKDIR /root/build
CMD ['/bin/bash']