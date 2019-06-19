#Set version of Ubuntu base image

ARG DOCKER_OPENSTUDIO_VERSION=2.8.1
FROM nrel/openstudio:$DOCKER_OPENSTUDIO_VERSION

ARG OPENSTUDIO_VERSION=2.8.1
ENV OPENSTUDIO_VERSION ${OPENSTUDIO_VERSION}

MAINTAINER Nicholas Long nicholas.long@nrel.gov
# Set up Display Environment. This optionally allows X11 connections
# if DISPLAY is passed as an argument.
ARG DISPLAY=local

ENV DISPLAY ${DISPLAY}

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
	wget '
	
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
	zlib1g-dev \ 
	libtool \ 
	autoconf'

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
&& echo "export RUBYLIB=/usr/local/openstudio-$OPENSTUDIO_VERSION/Ruby:/usr/Ruby" >> /etc/user_config_bashrc \
&& echo "export ENERGYPLUS_EXE_PATH=/usr/local/openstudio-${OPENSTUDIO_VERSION}/EnergyPlus/energyplus" >> /etc/user_config_bashrc \
&& echo  "$YEL******Aliasing OpenStudioApp so it can run anywhere.*****$NC"	\
&& echo 'alias OpenStudioApp=/usr/local/bin/OpenStudioApp' >> /etc/user_config_bashrc \
&& echo  "$YEL******Adding Git colors to bash prompt*****$NC"	\
&& echo 'source /usr/lib/git-core/git-sh-prompt' >> /etc/user_config_bashrc \
&& echo 'red=$(tput setaf 1) && green=$(tput setaf 2) && yellow=$(tput setaf 3) &&  blue=$(tput setaf 4) && magenta=$(tput setaf 5) && reset=$(tput sgr0) && bold=$(tput bold)' >> /etc/user_config_bashrc \ 
&& echo PS1=\''\[$magenta\]\u\[$reset\]@\[$green\]\h\[$reset\]:\[$blue\]\w\[$reset\]\[$yellow\][$(__git_ps1 "%s")]\[$reset\]\$'\' >> /etc/user_config_bashrc \
&& echo "$YEL*****Installing bundle and nokogiri gems on root. Needs to be run under bash *****$NC" \
&& /bin/bash -c "source /etc/user_config_bashrc && gem install --no-ri --no-rdoc bundler -v 1.16.4 && gem install --no-ri --no-rdoc nokogiri -v 1.8.4" \
&& echo "$YEL*****Setting gem folder to be accessible by users *****$NC" \
&& chmod -R 777 /usr/local/lib/ruby/gems \
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
