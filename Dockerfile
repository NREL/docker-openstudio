FROM ubuntu:22.04 AS base

LABEL maintainer="Nicholas Long nicholas.long@nrel.gov"

# Set the version of OpenStudio when building the container. For example `docker build --build-arg
ARG OPENSTUDIO_VERSION=3.11.0
ARG OPENSTUDIO_VERSION_EXT="-rc1"
ARG OPENSTUDIO_SHA="dee62bf9dd"
# If OPENSTUDIO_DOWNLOAD_URL is not provided, construct a reasonable default using the
# OpenStudio CI S3 pattern. Users can override by passing --build-arg OPENSTUDIO_DOWNLOAD_URL=...
ARG OPENSTUDIO_DOWNLOAD_URL=""
ENV RC_RELEASE=TRUE
ENV OS_BUNDLER_VERSION=2.4.10
ENV RUBY_VERSION=3.2.2
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
    && if [ -z "${OPENSTUDIO_DOWNLOAD_URL}" ]; then \
    ESC_VERSION=$(echo "${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}" | sed 's/+/%2B/g'); \
    if [ -n "${OPENSTUDIO_SHA}" ]; then \
    OPENSTUDIO_DOWNLOAD_URL="https://openstudio-ci-builds.s3.amazonaws.com/develop/OpenStudio-${ESC_VERSION}%2B${OPENSTUDIO_SHA}-Ubuntu-22.04-x86_64.deb"; \
    else \
    OPENSTUDIO_DOWNLOAD_URL="https://openstudio-ci-builds.s3.amazonaws.com/develop/OpenStudio-${ESC_VERSION}-Ubuntu-22.04-x86_64.deb"; \
    fi; \
    fi \
    && echo "OpenStudio Package Download URL is ${OPENSTUDIO_DOWNLOAD_URL}" \
    && curl -SLO "$OPENSTUDIO_DOWNLOAD_URL" \
    && OPENSTUDIO_DOWNLOAD_FILENAME=$(ls *.deb) \
    # Verify that the download was successful (not access denied XML from s3)
    && grep -v -q "<Code>AccessDenied</Code>" ${OPENSTUDIO_DOWNLOAD_FILENAME} \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    # Cleanup
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure locales

RUN apt update && apt install -y libyaml-dev ruby-full 
# RUN apt-get install ca-certificates 
RUN pwd
RUN curl -SLO -k https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz \
    && tar -xvzf ruby-3.2.2.tar.gz \
    && cd ruby-3.2.2 \
    && ./configure \
    && make && make install 

## Detect the OpenStudio installation folder
## The folder will be openstudio-3.9.0 or something like openstudio-3.9.0-alpha
## We search for any folder matching the version pattern to handle various naming conventions

RUN echo "Searching for OpenStudio installation..." \
    && ls -la /usr/local \
    && ls -la /usr \
    && OPENSTUDIO_FOLDER=$(find /usr -maxdepth 2 -type d -name "openstudio-${OPENSTUDIO_VERSION}*" 2>/dev/null | head -1) \
    && if [ -z "$OPENSTUDIO_FOLDER" ]; then \
    echo "ERROR: OpenStudio folder not found matching pattern openstudio-${OPENSTUDIO_VERSION}*"; \
    echo "Searching for any openstudio folder..."; \
    find /usr -maxdepth 2 -type d -name "openstudio-*" 2>/dev/null; \
    exit 1; \
    fi \
    && echo "OpenStudio folder is ${OPENSTUDIO_FOLDER}" \
    && ls -la ${OPENSTUDIO_FOLDER} \
    && rm -rf ruby* \
    && gem install bundler -v $OS_BUNDLER_VERSION \
    && gem install zip \
    && mkdir /var/oscli \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/Gemfile /var/oscli/ \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/Gemfile.lock /var/oscli/ \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/openstudio-gems.gemspec /var/oscli/ \
    && ln -s ${OPENSTUDIO_FOLDER} /usr/local/openstudio-${OPENSTUDIO_VERSION}

ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby
ENV ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}/EnergyPlus/energyplus

RUN rm -rf ruby*
## Add RUBYLIB link for openstudio.rb
ENV RUBYLIB=/usr/local/openstudio-${OPENSTUDIO_VERSION}/Ruby
ENV ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}/EnergyPlus/energyplus

WORKDIR /var/oscli
RUN bundle -v
RUN bundle _${OS_BUNDLER_VERSION}_ install --path=gems --without=native_ext --jobs=4 --retry=3

# Configure the bootdir & confirm that openstudio is able to load the bundled gem set in /var/gemdata
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
RUN openstudio --loglevel Trace --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems --bundle_without native_ext gem_list

# May need this for syscalls that do not have ext in path

CMD [ "/bin/bash" ]
