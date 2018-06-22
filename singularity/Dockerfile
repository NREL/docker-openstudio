FROM ubuntu:18.04

ENV SINGULARITY_VERSION=2.5.1
RUN apt-get update && apt-get install -y --no-install-recommends \
        # singularity dependencies
        build-essential \
        python \
        libarchive-dev \
        squashfs-tools \
        # other dependencies
        curl \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        gnupg \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce \
    && rm -rf /var/lib/apt/lists/*

# Build and install singularity
WORKDIR /root/singularity-build
RUN curl -SLO https://github.com/singularityware/singularity/releases/download/$SINGULARITY_VERSION/singularity-$SINGULARITY_VERSION.tar.gz \
    && tar xvf singularity-$SINGULARITY_VERSION.tar.gz \
    && cd singularity-$SINGULARITY_VERSION \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && singularity --version

WORKDIR /root/build
CMD ['/bin/bash']