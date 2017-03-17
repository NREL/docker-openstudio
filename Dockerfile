FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov
#Set up Display Environment
ARG DISPLAY=local
ENV DISPLAY ${DISPLAY}

# Set Version of software
ARG OPENSTUDIO_VERSION=2.0.4
ARG OPENSTUDIO_SHA=85b68591e6
ARG RUBYVERSION=2.2.4

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby.
ARG OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb
RUN apt-get update && apt-get install -y ca-certificates curl gdebi-core git libglu1 libjpeg8 libfreetype6 libxi6 \
    build-essential libssl-dev libreadline-dev zlib1g-dev libxml2-dev libdbus-glib-1-2 libfontconfig1 libsm6 libnss3 \
    && curl -SLO https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/$OPENSTUDIO_DOWNLOAD_FILENAME \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /usr/SketchUpPlugin \
    && rm -rf /var/lib/apt/lists/*

# Build and install Ruby 2.0 using rbenv for flexibility
RUN git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
ENV RBENV_ROOT=/usr/local/rbenv
ENV PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
ENV RUBY_CONFIGURE_OPTS=--enable-shared
RUN eval "$(rbenv init -)"
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
RUN cd /usr/local/rbenv/plugins/ruby-build && /bin/bash -c "./install.sh"
RUN rbenv install $RUBYVERSION
RUN rbenv global $RUBYVERSION
## install bundler
RUN gem install bundler
## Add RUBYLIB link for openstudio.rb
ENV RUBYLIB /usr/Ruby

VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
