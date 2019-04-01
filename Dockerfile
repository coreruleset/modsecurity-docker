FROM httpd:2.4

# For fuzzylib
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

RUN apt-get -y update && \
    apt-get -y install git \
    libtool \
    dh-autoreconf \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libgeoip-dev \
    liblmdb-dev \
    lua5.2-dev \
    libpcre++-dev \
    doxygen \
    libyajl-dev \
    cmake

RUN cd /opt/ && \
    git clone https://github.com/ssdeep-project/ssdeep && \
    cd ssdeep && \
    ./bootstrap && \
    ./configure && make && make install


RUN cd /opt && \
    git clone -b v3/master https://github.com/SpiderLabs/ModSecurity

RUN cd /opt/ && \
    cd ModSecurity && \
    sh build.sh && \
    git submodule init && \
    git submodule update && \
    ./configure && \
    make && \
    make install

RUN cd /opt/ && \
    git clone https://github.com/SpiderLabs/ModSecurity-apache

RUN cd /opt/ModSecurity-apache/ && \
    ./autogen.sh && \
    ./configure --with-libmodsecurity=/usr/local/modsecurity/ && \
    make && \
    make install

RUN mkdir -p /etc/modsecurity.d/ && \
        echo "include /usr/local/apache2/conf/security.conf" >> /usr/local/apache2/conf/httpd.conf && \
        echo "LoadModule security3_module \"/usr/local/apache2/modules/mod_security3.so\"" > /usr/local/apache2/conf/security.conf && \
        echo "modsecurity_rules_file '/etc/modsecurity.d/include.conf'" >> /usr/local/apache2/conf/security.conf && \
        mv /opt/ModSecurity/modsecurity.conf-recommended /etc/modsecurity.d/modsecurity.conf && \
        mv /opt/ModSecurity/unicode.mapping /etc/modsecurity.d/ && \
        echo include modsecurity.conf >> /etc/modsecurity.d/include.conf

RUN ldconfig
