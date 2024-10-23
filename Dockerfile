FROM ubuntu:20.04 AS base

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Set the version of OpenStudio when building the container. For example `docker build --build-arg
ARG OPENSTUDIO_VERSION=3.8.0
ARG OPENSTUDIO_VERSION_EXT=""
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
    && echo "OpenStudio Package Download URL is ${OPENSTUDIO_DOWNLOAD_URL}" \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
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

## if the openstudio-${OPENSTUDIO_VERSION} folder existed, set it as the OPENSTUDIO 
## folder, otherwise set the openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT} folder
RUN if [ -d "/usr/local/openstudio-${OPENSTUDIO_VERSION}" ]; then \
    echo "OpenStudio folder is /usr/local/openstudio-${OPENSTUDIO_VERSION}"; \
    OPENSTUDIO_FOLDER=/usr/local/openstudio-${OPENSTUDIO_VERSION}; \
    else \
    echo "OpenStudio folder is /usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}"; \
    OPENSTUDIO_FOLDER=/usr/local/openstudio-${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}; \
    fi \
    && echo "OpenStudio folder is ${OPENSTUDIO_FOLDER}" \
    && rm -rf ruby* \
    && gem install bundler -v $OS_BUNDLER_VERSION \
    && mkdir /var/oscli \
    && ls /usr/local \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/Gemfile /var/oscli/ \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/Gemfile.lock /var/oscli/ \
    && cp ${OPENSTUDIO_FOLDER}/Ruby/openstudio-gems.gemspec /var/oscli/\
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
RUN openstudio --loglevel Trace --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems --bundle_without native_ext  openstudio_version

# May need this for syscalls that do not have ext in path

CMD [ "/bin/bash" ]