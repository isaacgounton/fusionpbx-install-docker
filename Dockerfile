FROM ubuntu:24.04
LABEL maintainer="michelfang <yingchih.fang@gmail.com>"
#==================================================================
#MODIFY YOUR DB CONFIG in src/fusionpbx-install.sh/ubuntu/resource/conig.sh
#==================================================================

##########################
#include preinstall.sh
#########################
# Set non-interactive mode for apt-get
RUN export DEBIAN_FRONTEND=noninteractive

#upgrade the packages
RUN apt-get update && apt-get upgrade -y

#install packages
# install required packages (git not needed when using local copy)
RUN apt-get install -y lsb-release git

WORKDIR /usr/src
RUN git clone https://github.com/fusionpbx/fusionpbx-install.sh.git

#change the working directory
# make sure installer scripts are executable and run the installer
RUN chmod -R +x /usr/src/fusionpbx-install.sh 

COPY ./config.sh  /usr/src/fusionpbx-install.sh/ubuntu/resources/config.sh
# Source common environment files before running any scripts that rely on them
# Set working directory where resources/scripts will be located
WORKDIR /usr/src/fusionpbx-install.sh/ubuntu

############################
#equal to install.sh
############################


# Remove cdrom sources from apt list and update/upgrade packages
RUN sed -i '/cdrom:/d' /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade -y

# Install system dependencies (excluding systemd and PostgreSQL)
RUN apt-get install -y \
    wget \
    lsb-release \
    ca-certificates \
    dialog \
    nano \
    nginx \
    build-essential \
    snmpd \
    supervisor

# Configure SNMP community and restart service
RUN echo "rocommunity public" > /etc/snmp/snmpd.conf && \
    service snmpd restart

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/iptables.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/sngrep.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/fusionpbx.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/php.sh || true

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/nginx.sh ||true

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/postgresql.sh || echo "Skipping PostgreSQL installation for external DB"

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/applications.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/switch.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/fail2ban.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/finish.sh

RUN rm -rf /var/lib/apt/lists/*

# Create a simple startup script for Coolify compatibility
RUN echo '#!/bin/bash\n\
    service nginx start\n\
    service php8.3-fpm start\n\
    freeswitch -nc\n\
    tail -f /var/log/freeswitch/freeswitch.log' > /usr/local/bin/start-fusionpbx.sh && \
    chmod +x /usr/local/bin/start-fusionpbx.sh

ENTRYPOINT ["/usr/local/bin/start-fusionpbx.sh"]
