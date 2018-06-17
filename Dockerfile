FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# If installing a CI build version of OpenStudio, then pass in the CI path into the build command. For example:
#   docker build --build-arg DOWNLOAD_PREFIX="_CI/OpenStudio"
ARG DOWNLOAD_PREFIX=""

# Modify the OPENSTUDIO_VERSION and OPENSTUDIO_SHA for new versions
ENV OPENSTUDIO_VERSION=2.5.2 \
    OPENSTUDIO_SHA=8d7aa85fe5 \
    RUBY_VERSION=2.2.4 \
    RUBY_SHA=b6eff568b48e0fda76e5a36333175df049b204e91217aa32a65153cc0cdcb761

# Don't combine with above since ENV vars are not initialized until after the above call
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

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
    && if [ -z "${DOWNLOAD_PREFIX}" ]; then \
            export OPENSTUDIO_DOWNLOAD_URL=https://openstudio-builds.s3.amazonaws.com/$OPENSTUDIO_VERSION/OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb; \
       else \
            export OPENSTUDIO_DOWNLOAD_URL=https://openstudio-builds.s3.amazonaws.com/$DOWNLOAD_PREFIX/OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb; \
       fi \
    && echo "OpenStudio Package Download URL is ${OPENSTUDIO_DOWNLOAD_URL}" \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    # Verify that the download was successful (not access denied XML from s3)
    && grep -v -q "<Code>AccessDenied</Code>" ${OPENSTUDIO_DOWNLOAD_FILENAME} \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    # Cleanup
    && rm -f /usr/local/bin/install_ruby.sh \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && if dpkg --compare-versions "${OPENSTUDIO_VERSION}" "gt" "2.5.1"; then \
            rm -rf /usr/local/openstudio-${OPENSTUDIO_VERSION}/SketchUpPlugin; \
       else \
            rm -rf /usr/SketchUpPlugin; \
       fi

## Add RUBYLIB link for openstudio.rb. Support new location and old location.
ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby:/usr/Ruby

VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
