FROM ubuntu:18.04
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

RUN apt-get -y update && \
    apt-get -y install git \
    libtool \
    dh-autoreconf \
    pkgconf \
    libcurl4-gnutls-dev \
    libxml2 \
    libpcre++-dev \
    libxml2-dev \
    libgeoip-dev \
    libyajl-dev \
    liblmdb-dev \
    ssdeep \
    lua5.2-dev \
    apache2 \
    apache2-dev

RUN cd /opt && \
    git clone -b v3/master https://github.com/SpiderLabs/ModSecurity

RUN cd /opt/ModSecurity && \
    sh build.sh && \
    git submodule init && \
    git submodule update && \
    ./configure && \
    make && \
    make install

RUN ln -s /usr/sbin/apache2 /usr/sbin/httpd
 
    
RUN cd /opt && \
    git clone https://github.com/SpiderLabs/ModSecurity-apache

RUN cd /opt/ModSecurity-apache/ && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install
    
RUN mkdir -p /etc/apache2/modsecurity.d/ && \
    echo "LoadModule security3_module \"$(find /opt/ModSecurity-apache/ -name mod_security3.so)\"" > /etc/apache2/mods-enabled/security.conf && \
    echo "modsecurity_rules 'SecRuleEngine On'" >> /etc/apache2/mods-enabled/security.conf && \
    echo "modsecurity_rules_file '/etc/apache2/modsecurity.d/include.conf'" >> /etc/apache2/mods-enabled/security.conf
    

RUN cd /etc/apache2/modsecurity.d/  && \
    mv /opt/ModSecurity/modsecurity.conf-recommended /etc/apache2/modsecurity.d/modsecurity.conf && \
    echo include modsecurity.conf >> /etc/apache2/modsecurity.d/include.conf && \
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs owasp-crs && \
    mv /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf.example /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf && \
    echo include owasp-crs/crs-setup.conf >> /etc/apache2/modsecurity.d/include.conf && \
    echo include owasp-crs/rules/\*.conf >> /etc/apache2/modsecurity.d/include.conf
    
EXPOSE 80

CMD ["httpd", "-D", "FOREGROUND"]
