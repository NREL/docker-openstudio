FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Run this separate to cache the download (from S3)
# Modify the OPENSTUDIO_VERSION and OPENSTUDIO_SHA for new versions
ENV OPENSTUDIO_VERSION=2.4.1 \
    OPENSTUDIO_SHA=fcd9a4317a

# Filenames for download from S3
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb \
    OPENSTUDIO_DOWNLOAD_URL=https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

# Install gdebi, then download and install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby 2.2.4.
RUN apt-get update && apt-get install -y ca-certificates curl gdebi-core git libglu1 libjpeg8 libfreetype6 libxi6 \
    build-essential libssl-dev libreadline-dev zlib1g-dev libxml2-dev libdbus-glib-1-2 libfontconfig1 libsm6 \
    && curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /usr/SketchUpPlugin \
    && rm -rf /var/lib/apt/lists/* \
    && `# Build and install Ruby 2.0 using rbenv for flexibility` \
    && git clone https://github.com/sstephenson/rbenv.git ~/.rbenv \
    && git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build \
    && RUBY_CONFIGURE_OPTS=--enable-shared ~/.rbenv/bin/rbenv install 2.2.4 \
    && ~/.rbenv/bin/rbenv global 2.2.4 \
    && `# Add rbenv path` \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
    && `# Add bundler gem` \
    && ~/.rbenv/shims/gem install bundler


# Add RUBYLIB link for openstudio.rb and Ruby path based on the shim installed
ENV RUBYLIB=/usr/Ruby \
    PATH="/root/.rbenv/shims:$PATH"

# Test file
COPY test.rb /root/test.rb

VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
