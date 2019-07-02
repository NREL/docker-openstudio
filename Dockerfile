FROM ubuntu:18.04 AS base

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# If installing a CI build version of OpenStudio, then pass in the CI path into the build command. For example:
#   docker build --build-arg DOWNLOAD_PREFIX="_CI/OpenStudio"
# ARG DOWNLOAD_PREFIX=""

# Set the version of OpenStudio when building the container. For example `docker build --build-arg
# OPENSTUDIO_VERSION=2.6.0 --build-arg OPENSTUDIO_SHA=e3cb91f98a .` in the .travis.yml. Set with the ENV keyword to
# inherit the variables into child containers
ARG OPENSTUDIO_VERSION=2.8.1
# ARG OPENSTUDIO_VERSION_EXT
# ARG OPENSTUDIO_SHA
ARG OS_BUNDLER_VERSION=1.17.1
# ENV OPENSTUDIO_VERSION=$OPENSTUDIO_VERSION
# ENV OPENSTUDIO_VERSION_EXT=$OPENSTUDIO_VERSION_EXT
# ENV OPENSTUDIO_SHA=$OPENSTUDIO_SHA
# ENV OS_BUNDLER_VERSION=$OS_BUNDLER_VERSION
ENV RUBY_VERSION=2.5.1

# Don't combine with above since ENV vars are not initialized until after the above call
# ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION$OPENSTUDIO_VERSION_EXT.$OPENSTUDIO_SHA-Linux.deb
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio3-prerelease-rc1.d3ec7ff9b5-2.8.1-Linux.deb

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies

# install locales and set to en_US.UTF-8. This is needed for running the CLI on some machines
# such as singularity.
RUN apt-get update && apt-get install -y \
     #    autoconf \
     #    build-essential \
     #    ca-certificates \
        curl \
        gdebi-core \
        # will we care that we can't lock to 2.5.1 specifically?
        ruby2.5 \ 
        git \
     #    libfreetype6 \
     #    libjpeg8 \
     #    libdbus-glib-1-2 \
     #    libfontconfig1 \
     #    libglu1 \
     #    libreadline-dev \
     #    libsm6 \
     #    libssl-dev \
     #    libtool \
     #    libwxgtk3.0-0v5 \
     #    libxi6 \
     #    libxml2-dev \
	   locales \
     #    sudo \
     #    zlib1g-dev \
    && export OPENSTUDIO_DOWNLOAD_URL=https://openstudio-ci-builds.s3-us-west-2.amazonaws.com/develop3/$OPENSTUDIO_DOWNLOAD_FILENAME \

    && echo "OpenStudio Package Download URL is ${OPENSTUDIO_DOWNLOAD_URL}" \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    # Verify that the download was successful (not access denied XML from s3)
    && grep -v -q "<Code>AccessDenied</Code>" ${OPENSTUDIO_DOWNLOAD_FILENAME} \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME 
    # Cleanup
    RUN rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure locales


## Add RUBYLIB link for openstudio.rb
ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby
ENV ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}/EnergyPlus/energyplus

# The OpenStudio Gemfile contains a fixed bundler version, so you have to install and run specific to that version
RUN gem install bundler -v $OS_BUNDLER_VERSION && \
    mkdir /var/oscli && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby/Gemfile /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby/Gemfile.lock /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby/openstudio-gems.gemspec /var/oscli/
WORKDIR /var/oscli
RUN bundle _${OS_BUNDLER_VERSION}_ install --path=gems --jobs=4 --retry=3

# Configure the bootdir & confirm that openstudio is able to load the bundled gem set in /var/gemdata
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
# RUN openstudio --verbose --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems openstudio_version

CMD [ "/bin/bash" ]
