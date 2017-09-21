#Set version of Ubuntu base image.
FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov
# Set up Display Environment. This optionally allows X11 connections
# if DISPLAY is passed as an argument.
ARG DISPLAY=local
ENV DISPLAY ${DISPLAY}

# Set Version of software of OpenStudio, and Ruby.

#ENV OPENSTUDIO_VERSION 2.2.2
#ENV OPENSTUDIO_SHA ebdeaa44f8

#ARG OPENSTUDIO_VERSION=2.2.0
#ARG OPENSTUDIO_SHA=0a5e9cec3f

ARG OPENSTUDIO_VERSION=2.2.1
ARG OPENSTUDIO_SHA=92a7ed37f1

ARG OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb
ARG OPENSTUDIO_BUILDS_URL=https://s3.amazonaws.com/openstudio-builds
ARG RUBYVERSION=2.2.4
ARG CHRUBY_VERSION=0.3.9
ARG RUBYINSTALL_VERSION=0.6.1

#Colors for output to make docker echo commands a bit more readable. 
ARG YEL='\033[0;33m'
ARG NC='\033[0m'

# ENV variables ensured to be available during /bin/sh shell installation.
# A more permanant solution will be set in .bashrc below. 
ENV RUBYLIB /usr/Ruby

#Required Software and libraries.
## System Software
ARG SYSTEM_SOFTWARE=' \
	build-essential \ 
	ca-certificates \ 
	curl \ 
	gdebi-core \ 
	git \
	nano \ 
	wget'
	
## OpenStudio Dependant Libraries for Ubuntu 14.04 that gdebi does not satisfy
## in installation below.					
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

#Install Software and libraries, install ruby, install OpenStudio, 
# set environment varialble and aliases for ruby and Openstudio. Create 
# bashrc prompt customization for git for users, and clean apt-get software list. 
RUN echo "$YEL*****Installing Software and deps using apt-get*****$NC" \ 
&& apt-get update && apt-get install -y --no-install-recommends --force-yes \ 
	$SYSTEM_SOFTWARE \
	$OPENSTUDIOAPP_DEPS \
&& echo  "$YEL******Customizing bash shell*****$NC"	\
&& touch /etc/user_config_bashrc && chmod 755 /etc/user_config_bashrc \
&& echo "$YEL******Set root env configuration by adding script to /root/.bashrc*****$NC" \
&& echo 'source /etc/user_config_bashrc' >> ~/.bashrc \
&& echo  "$YEL******Adding E+ to path*****$NC"	\
&& echo 'export PATH="/usr/EnergyPlus:$PATH"' >> /etc/user_config_bashrc \
&& echo  "$YEL******Adding OpenStudio libs to RUBYLIB*****$NC"	\
&& echo 'export RUBYLIB="/usr/Ruby"' >> /etc/user_config_bashrc \
&& echo  "$YEL******Aliasing OpenStudioApp so it can run anywhere.*****$NC"	\
&& echo 'alias OpenStudioApp=/usr/bin/OpenStudioApp' >> /etc/user_config_bashrc \
&& echo  "$YEL******Adding Git colors to bash prompt*****$NC"	\
&& echo 'source /usr/lib/git-core/git-sh-prompt' >> /etc/user_config_bashrc \
&& echo 'red=$(tput setaf 1) && green=$(tput setaf 2) && yellow=$(tput setaf 3) &&  blue=$(tput setaf 4) && magenta=$(tput setaf 5) && reset=$(tput sgr0) && bold=$(tput bold)' >> /etc/user_config_bashrc \ 
&& echo PS1=\''\[$magenta\]\u\[$reset\]@\[$green\]\h\[$reset\]:\[$blue\]\w\[$reset\]\[$yellow\][$(__git_ps1 "%s")]\[$reset\]\$'\' >> /etc/user_config_bashrc \
&& echo  "$YEL******Downloading and Installing OpenStudio $OPENSTUDIO_VERSION*****$NC"	\
&& curl -SLO $OPENSTUDIO_BUILDS_URL/$OPENSTUDIO_VERSION/$OPENSTUDIO_DOWNLOAD_FILENAME \
&& gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -rf /usr/SketchUpPlugin \
&& echo "$YEL*****Installing RubyInstall $RUBYINSTALL_VERSION*****$NC" \
&& wget -O ruby-install-$RUBYINSTALL_VERSION.tar.gz https://github.com/postmodern/ruby-install/archive/v$RUBYINSTALL_VERSION.tar.gz \
&& tar -xzvf ruby-install-$RUBYINSTALL_VERSION.tar.gz \
&& cd ruby-install-$RUBYINSTALL_VERSION/ && make install \
&& echo "$YEL*****Installing Ruby $RUBYVERSION *****$NC" \
&& ruby-install ruby $RUBYVERSION \
&& echo "$YEL***** Installing chruby $CHRUBY_VERSION *****$NC" \
&& wget -O chruby-$CHRUBY_VERSION.tar.gz https://github.com/postmodern/chruby/archive/v$CHRUBY_VERSION.tar.gz \
&& tar -xzvf chruby-$CHRUBY_VERSION.tar.gz \
&& cd chruby-$CHRUBY_VERSION/ && make install \
&& echo "$YEL***** Adding chruby to all users profile *****$NC" \
&& echo 'if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then' >> /etc/profile.d/chruby.sh \
&& echo 'source /usr/local/share/chruby/chruby.sh' >> /etc/profile.d/chruby.sh \
&& echo 'source /usr/local/share/chruby/auto.sh' >> /etc/profile.d/chruby.sh \
&& echo 'chruby ruby-$RUBYVERSION'  >> /etc/profile.d/chruby.sh \
&& echo 'fi' >> /etc/profile.d/chruby.sh \
&& echo 'source /etc/profile.d/chruby.sh' >> /etc/user_config_bashrc \
&& echo "$YEL*****Installing bundle and nokogiri gems on root. Needs to be run under bash *****$NC" \
&& /bin/bash -c "source /etc/user_config_bashrc && chruby ruby-$RUBYVERSION && gem install --no-ri --no-rdoc bundler && gem install --no-ri --no-rdoc nokogiri" \
&& echo "$YEL*****Adding regular user called osdev and add to sudo group*****$NC" \
&& useradd -m osdev && echo "osdev:osdev" | chpasswd \
&& adduser osdev sudo \
&& echo "$YEL*****Clean up apt*****$NC" \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean 

USER osdev
RUN echo "$YEL*****Set user osdev env configuration by adding script to /home/osdev/.bashrc*****$NC"
RUN echo 'source /etc/user_config_bashrc' >> ~/.bashrc
RUN echo "$YEL*****Keeping default user as root for now to ensure compatibility*****$NC"
USER root

# Mount and set cwd
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio
CMD [ "/bin/bash" ]
