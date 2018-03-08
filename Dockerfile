FROM ubuntu:18.04
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

# Install Prereqs
RUN apt-get update && \
    apt-get -y install wget \
    libtool \
    automake \
    pkgconf \
    libcurl4-gnutls-dev \
    apache2 \
    apache2-dev \
    libpcre++-dev \
    libxml2-dev \
    lua5.2-dev \
    libyajl-dev \
    ssdeep &&\
    apt-get clean

# Download ModSecurity
RUN mkdir -p /usr/share/ModSecurity && \
  cd /usr/share/ModSecurity && \
  wget --quiet "https://github.com/SpiderLabs/ModSecurity/releases/download/v2.9.2/modsecurity-2.9.2.tar.gz" && \
  tar -xvzf modsecurity-2.9.2.tar.gz

# Install ModSecurity
RUN cd /usr/share/ModSecurity/modsecurity-2.9.2/ && \
  sh autogen.sh && \
  ./configure && \
  make && \
  make install && \
  make clean

# Move Files
RUN cd /usr/share/ModSecurity/modsecurity-2.9.2/ && \
  mkdir -p /etc/apache2/modsecurity.d && \
  mv modsecurity.conf-recommended  /etc/apache2/modsecurity.d/modsecurity.conf && \
  mv unicode.mapping /etc/apache2/modsecurity.d/
  
# Enable Mod_Unique_id
RUN mv /etc/apache2/mods-available/unique_id.load /etc/apache2/mods-enabled/

# Setup Config
RUN printf "LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so\nInclude modsecurity.d/*.conf" > /etc/apache2/mods-enabled/10-modsecurty.conf && \
  echo "ServerName localhost" > /etc/apache2/conf-enabled/ServerName.conf

# Remove Apache defaults
RUN printf "hello world" > /var/www/html/index.html

EXPOSE 80

CMD ["apachectl", "-D", "FOREGROUND"]