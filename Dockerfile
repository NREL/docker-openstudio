FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Run this separate to cache the download
ENV OPENSTUDIO_VERSION 2.0.4
ENV OPENSTUDIO_SHA 85b68591e6

# Download from S3
ENV OPENSTUDIO_DOWNLOAD_BASE_URL https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION
ENV OPENSTUDIO_DOWNLOAD_FILENAME OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb
ENV OPENSTUDIO_DOWNLOAD_URL $OPENSTUDIO_DOWNLOAD_BASE_URL/$OPENSTUDIO_DOWNLOAD_FILENAME

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby 2.2.4.

RUN apt-get update && apt-get install -y ca-certificates curl gdebi-core git \
    build-essential libssl-dev libreadline-dev zlib1g-dev libxml2-dev \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/local/lib/openstudio-$OPENSTUDIO_VERSION/ruby/2.0/openstudio/sketchup_plugin

# Build and install Ruby 2.0 using rbenv for flexibility
RUN git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN RUBY_CONFIGURE_OPTS=--enable-shared ~/.rbenv/bin/rbenv install 2.2.4
RUN ~/.rbenv/bin/rbenv global 2.2.4

RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# Add bundler gem
RUN ~/.rbenv/shims/gem install bundler

# Add RUBYLIB link for openstudio.rb
ENV RUBYLIB /usr/Ruby

VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
