FROM ubuntu:20.04 AS base

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Set the version of OpenStudio when building the container. For example `docker build --build-arg
ARG OPENSTUDIO_VERSION=3.4.0
ARG OPENSTUDIO_VERSION_EXT=""
ARG OPENSTUDIO_DOWNLOAD_URL=https://openstudio-builds.s3.amazonaws.com/3.4.0/OpenStudio-3.4.0%2B4bd816f785-Ubuntu-18.04.deb

ENV OS_BUNDLER_VERSION=2.1.4
ENV RUBY_VERSION=2.7.2
ENV BUNDLE_WITHOUT=native_ext
# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies

# install locales and set to en_US.UTF-8. This is needed for running the CLI on some machines
# such as singularity.
RUN apt-get update && apt-get install -y \
        curl \
        gdebi-core \
        libsqlite3-dev \
        libssl-dev \ 
        libffi-dev \ 
        build-essential \
        zlib1g-dev \
        vim \ 
        git \
        locales \
        sudo \
    && echo "OpenStudio Package Download URL is ${OPENSTUDIO_DOWNLOAD_URL}" \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    && OPENSTUDIO_DOWNLOAD_FILENAME=$(ls *.deb) \
    # Verify that the download was successful (not access denied XML from s3)
    && grep -v -q "<Code>AccessDenied</Code>" ${OPENSTUDIO_DOWNLOAD_FILENAME} \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME 
    # Cleanup
    RUN rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure locales


RUN curl -SLO https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.gz \
    && tar -xvzf ruby-2.7.2.tar.gz \
    && cd ruby-2.7.2 \
    && ./configure \
    && make && make install 


## Add RUBYLIB link for openstudio.rb
ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby
ENV ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/EnergyPlus/energyplus

# The OpenStudio Gemfile contains a fixed bundler version, so you have to install and run specific to that version
RUN gem install bundler -v $OS_BUNDLER_VERSION && \
    mkdir /var/oscli && \
    ls /usr/local && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/Gemfile /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/Gemfile.lock /var/oscli/ && \
    cp /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}/Ruby/openstudio-gems.gemspec /var/oscli/
WORKDIR /var/oscli
RUN bundle -v
RUN bundle _${OS_BUNDLER_VERSION}_ install --path=gems --without=native_ext --jobs=4 --retry=3

# Configure the bootdir & confirm that openstudio is able to load the bundled gem set in /var/gemdata
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
RUN openstudio --verbose --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems --bundle_without native_ext  openstudio_version

# May need this for syscalls that do not have ext in path
RUN ln -s /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT} /usr/local/openstudio-${OPENSTUDIO_VERSION}

CMD [ "/bin/bash" ]
