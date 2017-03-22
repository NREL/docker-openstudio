#Set version of Ubuntu base image.
FROM ubuntu:14.04

MAINTAINER Nicholas Long nicholas.long@nrel.gov
# Set up Display Environment. This optionally allows X11 connections
# if DISPLAY is passed as an argument.
ARG DISPLAY=local
ENV DISPLAY ${DISPLAY}

# Set Version of software of OpenStudio, and Ruby.
ARG OPENSTUDIO_VERSION=2.0.4
ARG OPENSTUDIO_SHA=85b68591e6
ARG RUBYVERSION=2.2.4
ARG CHRUBY_VERSION=0.3.9
ARG RUBYINSTALL_VERSION=0.6.1
ARG OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

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
	wget	'
	
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
RUN echo "*****Installing Software and deps using apt-get" \ 
&& apt-get update && apt-get install -y --no-install-recommends --force-yes \ 
	$SYSTEM_SOFTWARE \
	$OPENSTUDIOAPP_DEPS \
&& echo  "******Customizing bash shell"	\
&& touch /etc/user_config_bashrc && chmod 755 /etc/user_config_bashrc \
&& echo 'export PATH="/usr/EnergyPlus:$PATH"' >> /etc/user_config_bashrc \
&& echo 'export RUBYLIB="/usr/Ruby"' >> /etc/user_config_bashrc \
&& echo 'alias OpenStudioApp=/usr/bin/OpenStudioApp' >> /etc/user_config_bashrc \
&& echo 'source /usr/lib/git-core/git-sh-prompt' >> /etc/user_config_bashrc \
&& echo 'red=$(tput setaf 1) && green=$(tput setaf 2) && yellow=$(tput setaf 3) &&  blue=$(tput setaf 4) && magenta=$(tput setaf 5) && reset=$(tput sgr0) && bold=$(tput bold)' >> /etc/user_config_bashrc \ 
&& echo PS1=\''\[$magenta\]\u\[$reset\]@\[$green\]\h\[$reset\]:\[$blue\]\w\[$reset\]\[$yellow\][$(__git_ps1 "%s")]\[$reset\]\$'\' >> /etc/user_config_bashrc \
&& curl -SLO https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/$OPENSTUDIO_DOWNLOAD_FILENAME \
&& echo "*****Installing OpenStudio $OPENSTUDIO_VERSION" \
&& gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -rf /usr/SketchUpPlugin \
&& echo "*****Installing RubyInstall\ $RUBYINSTALL_VERSION" \
&& wget -O ruby-install-$RUBYINSTALL_VERSION.tar.gz https://github.com/postmodern/ruby-install/archive/v$RUBYINSTALL_VERSION.tar.gz \
&& tar -xzvf ruby-install-$RUBYINSTALL_VERSION.tar.gz \
&& cd ruby-install-$RUBYINSTALL_VERSION/ && make install \
&& echo "*****Installing Ruby $RUBYVERSION" \
&& ruby-install ruby $RUBYVERSION \
&& echo "Installing chruby $CHRUBY_VERSION" \
&& wget -O chruby-$CHRUBY_VERSION.tar.gz https://github.com/postmodern/chruby/archive/v$CHRUBY_VERSION.tar.gz \
&& tar -xzvf chruby-$CHRUBY_VERSION.tar.gz \
&& cd chruby-$CHRUBY_VERSION/ && make install \
&& echo 'if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then' >> /etc/profile.d/chruby.sh \
&& echo 'source /usr/local/share/chruby/chruby.sh' >> /etc/profile.d/chruby.sh \
&& echo 'source /usr/local/share/chruby/auto.sh' >> /etc/profile.d/chruby.sh \
&& echo 'chruby ruby-$RUBYVERSION'  >> /etc/profile.d/chruby.sh \
&& echo 'fi' >> /etc/profile.d/chruby.sh \
&& echo 'source /etc/profile.d/chruby.sh' >> /etc/user_config_bashrc \
&& echo "*****Installing bundle and nokogiri gems." \
&& /bin/bash -c "source /etc/user_config_bashrc && chruby ruby-$RUBYVERSION && gem install --no-ri --no-rdoc bundler && gem install --no-ri --no-rdoc nokogiri" \
&& echo "*****set root env configuration by adding script to /root/.bashrc" \
&& echo 'source /etc/user_config_bashrc' >> ~/.bashrc \
&& echo "*****Adding regular user called osdev" \
&& useradd -m osdev && echo "osdev:osdev" | chpasswd \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean \
&& echo "*****Add regular user" \
&& adduser osdev sudo

USER osdev
#set user osdev env configuration by added script to /home/osdev/.bashrc
RUN echo 'source /etc/user_config_bashrc' >> ~/.bashrc

#Keeping default user as root for now to ensure compatibility.
USER root

# Mount and set cwd
VOLUME /var/simdata/openstudio
WORKDIR /var/simdata/openstudio

CMD [ "/bin/bash" ]
