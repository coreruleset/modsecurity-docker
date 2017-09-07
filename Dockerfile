FROM fedora:25
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

# Install Prereqs
RUN dnf -y update && \
  dnf install -y httpd \
  httpd-devel \
  lua-devel \
  pcre-devel \
  libxml2-devel \
  libcurl-devel \
  libtool \
  yajl-devel \
  git \
  unzip \
  ssdeep \
  gcc \
  wget && \
  dnf clean all

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
  mkdir -p /etc/httpd/modsecurity.d && \
  mv modsecurity.conf-recommended  /etc/httpd/modsecurity.d/modsecurity.conf && \
  mv unicode.mapping /etc/httpd/modsecurity.d/

# Setup Config
Run printf "LoadModule security2_module modules/mod_security2.so\nInclude modsecurity.d/*.conf" > /etc/httpd/conf.modules.d/10-modsecurty.conf && \
  echo "ServerName localhost" > /etc/httpd/conf.d/ServerName.conf

# Remove Apache defaults
Run rm -f /etc/httpd/conf.d/welcome.conf && \
  printf "hello world" > /var/www/html/index.html

EXPOSE 80

CMD ["httpd", "-D", "FOREGROUND"]
