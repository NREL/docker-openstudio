FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov
#Set up Display Environment
ARG DISPLAY=local
ENV DISPLAY ${DISPLAY}

# Set Version of software
ARG OPENSTUDIO_VERSION=2.0.4
ARG OPENSTUDIO_SHA=85b68591e6
ARG RUBYVERSION=2.2.4

#Required Software and libraries.
## System Software
ARG SYSTEM_SOFTWARE=' \
	build-essential \ 
	ca-certificates \ 
	curl \ 
	gdebi-core \ 
	git '
	
## OpenStudio Dependant Libraries for Ubuntu 14.04 that gdeb does not satisfy.					
ARG OPENSTUDIOAPP_DEPS=' \
	libasound2	\
	libdbus-glib-1-2 \ 
	libfontconfig1 \
	libfreetype6 \ 
	libglu1 \ 
	libjpeg8 \
	libnss3 \
	libreadline-dev \ 
	libsm6 \
	libssl-dev \
	libxcomposite1 \
	libxcursor1 \ 
	libxi6 \
	libxml2-dev \ 
	libxtst6 \
	zlib1g-dev'
	
#Install Software and libraries.
RUN apt-get update && apt-get install -y --no-install-recommends --force-yes \ 
	$SYSTEM_SOFTWARE \
	$OPENSTUDIOAPP_DEPS \	
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean	
	
# Build and install Ruby 2.0 using rbenv for flexibility
## Set up ruby env variables and RUBYLIB for OpenStudio
ENV RBENV_ROOT=/usr/local/rbenv
ENV PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
ENV RUBY_CONFIGURE_OPTS=--enable-shared
ENV RUBYLIB /usr/Ruby
## Download, compile and install ruby version $RUBYVERSION and bundler gem.
RUN git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv \
&& eval "$(rbenv init -)" \
&& git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build \
&& cd /usr/local/rbenv/plugins/ruby-build && /bin/bash -c "./install.sh" \
&& rbenv install $RUBYVERSION \
&& rbenv global $RUBYVERSION \
&& rbenv rehash \
&& gem install bundler	\
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean	
		
# Install OpenStudio, then clean up.
# gdebi handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby. For some reason OpenStudioApp will only run if full path is provided, so created an alias.
ARG OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb
RUN curl -SLO https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/$OPENSTUDIO_DOWNLOAD_FILENAME \
&& gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -rf /usr/SketchUpPlugin \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean



RUN echo 'export RBENV_ROOT="/usr/local/rbenv"' >> ~/.bashrc 
RUN echo 'export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH:$PATH"' >> ~/.bashrc 
RUN echo 'export PATH="/usr/EnergyPlus:$PATH"' >> ~/.bashrc
RUN echo 'export RUBYLIB="/usr/Ruby"' >> ~/.bashrc
RUN echo 'alias OpenStudioApp=/usr/bin/OpenStudioApp' >> ~/.bashrc
RUN echo 'source /usr/lib/git-core/git-sh-prompt' >> ~/.bashrc
RUN echo 'red=$(tput setaf 1) && green=$(tput setaf 2) && yellow=$(tput setaf 3) &&  blue=$(tput setaf 4) && magenta=$(tput setaf 5) && reset=$(tput sgr0) && bold=$(tput bold)' >> ~/.bashrc 
RUN echo PS1=\''\[$magenta\]\u\[$reset\]@\[$green\]\h\[$reset\]:\[$blue\]\w\[$reset\]\[$yellow\][$(__git_ps1 "%s")]\[$reset\]\$'\' >> ~/.bashrc


#  Mount and set cwd
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
ENTRYPOINT ["/bin/bash"]
#CMD [ "/bin/bash" ]
