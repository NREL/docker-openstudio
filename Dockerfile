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
ARG OPENSTUDIO_DOWNLOAD_FILENAME=OpenStudio-$OPENSTUDIO_VERSION.$OPENSTUDIO_SHA-Linux.deb

# ENV variables ensured to be available during /bin/sh shell installation.
# A more permanant solution will be set in .bashrc below. 
ENV RBENV_ROOT=/usr/local/rbenv
ENV PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
ENV RUBY_CONFIGURE_OPTS=--enable-shared
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
RUN apt-get update && apt-get install -y --no-install-recommends --force-yes \ 
	$SYSTEM_SOFTWARE \
	$OPENSTUDIOAPP_DEPS \	
&& touch /etc/user_config_bashrc && chmod 755 /etc/user_config_bashrc \
&& echo 'alias OpenStudioApp=/usr/bin/OpenStudioApp' >> /etc/user_config_bashrc \
&& echo 'source /usr/lib/git-core/git-sh-prompt' >> /etc/user_config_bashrc \
&& echo 'red=$(tput setaf 1) && green=$(tput setaf 2) && yellow=$(tput setaf 3) &&  blue=$(tput setaf 4) && magenta=$(tput setaf 5) && reset=$(tput sgr0) && bold=$(tput bold)' >> /etc/user_config_bashrc \ 
&& echo PS1=\''\[$magenta\]\u\[$reset\]@\[$green\]\h\[$reset\]:\[$blue\]\w\[$reset\]\[$yellow\][$(__git_ps1 "%s")]\[$reset\]\$'\' >> /etc/user_config_bashrc \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& apt-get clean

RUN curl -SLO https://s3.amazonaws.com/openstudio-builds/$OPENSTUDIO_VERSION/$OPENSTUDIO_DOWNLOAD_FILENAME \
&& gdebi -n $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -f $OPENSTUDIO_DOWNLOAD_FILENAME \
&& rm -rf /usr/SketchUpPlugin 

RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build \
&& cd /usr/local/rbenv/plugins/ruby-build && /bin/bash -c "./install.sh" 
RUN wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
RUN tar -xzvf chruby-0.3.9.tar.gz
RUN cd chruby-0.3.9/ && make install
RUN ruby-build $RUBYVERSION /opt/rubies/ruby-$RUBYVERSION
#Configure Ruby for all users.
RUN echo 'if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then \n source /usr/local/share/chruby/chruby.sh \n fi' >> /etc/profile.d/chruby.sh
RUN /bin/bash -c "source /etc/profile.d/chruby.sh && chruby ruby-$RUBYVERSION && gem install --no-ri --no-rdoc bundler && gem install --no-ri --no-rdoc nokogiri"

#set root env configuration by add script to /root/.bashrc
RUN echo 'source /etc/user_config_bashrc' >> ~/.bashrc

#Add regular user called osdev
RUN useradd -m osdev && echo "osdev:osdev" | chpasswd \
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
