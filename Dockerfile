# This image uses the base one (ubuntu + dependencies and ruby)
# and simply installs OpenStudio on it
# docker build -f Dockerfile -t nrel/openstudio .
FROM nrel/openstudio:base

MAINTAINER Nicholas Long nicholas.long@nrel.gov

# Run this separate to cache the download (from S3)
# Modify the OPENSTUDIO_VERSION and OPENSTUDIO_SHA for new versions
ENV OPENSTUDIO_VERSION=2.4.1 \
    OPENSTUDIO_SHA=fcd9a4317a

# Filenames for download from S3
ENV OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb \
    OPENSTUDIO_DOWNLOAD_URL=https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

# Download OpenStudio and use previously installed gdebi to install it, then clean up.
RUN curl -SLO $OPENSTUDIO_DOWNLOAD_URL \
    && gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
    && rm -rf /usr/SketchUpPlugin \
    && rm -rf /var/lib/apt/lists/*
