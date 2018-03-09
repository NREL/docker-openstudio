FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Run this separate to cache the download (from S3)
# Modify the OPENSTUDIO_VERSION and OPENSTUDIO_SHA for new versions
ENV OPENSTUDIO_VERSION=2.4.3 \
    OPENSTUDIO_SHA=29a61f6637 \
    RUBY_VERSION=2.2.4 \
    RUBY_SHA=b6eff568b48e0fda76e5a36333175df049b204e91217aa32a65153cc0cdcb761

# Filenames for download from S3
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb \
    OPENSTUDIO_DOWNLOAD_URL=https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby 2.2.4.
# OpenStudio 2.4.3 requires libwxgtk3.0-0 -- install manually for now
RUN apt-get update && apt-get install -y autoconf \
        build-essential \
        ca-certificates \
        curl \
        gdebi-core \
        git \
        libfreetype6 \
        libjpeg8 \
        libdbus-glib-1-2 \
        libfontconfig1 \
        libglu1 \
        libreadline-dev \
        libsm6 \
        libssl-dev \
        libtool \
        libwxgtk3.0-0 \
        libxi6 \
        libxml2-dev \
        zlib1g-dev \
    && curl -sL https://raw.githubusercontent.com/NREL/OpenStudio-server/develop/docker/deployment/scripts/install_ruby.sh -o /usr/local/bin/install_ruby.sh \
    && chmod +x /usr/local/bin/install_ruby.sh \
    && /usr/local/bin/install_ruby.sh $RUBY_VERSION $RUBY_SHA \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /usr/SketchUpPlugin \
    && rm -rf /var/lib/apt/lists/*

## Add RUBYLIB link for openstudio.rb and Ruby path based on the shim installed
ENV RUBYLIB=/usr/Ruby

# Test file
COPY test.rb /root/test.rb

VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
