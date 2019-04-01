FROM httpd:2.4 as build
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

# Install Prereqs
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends --no-install-suggests \
      ca-certificates     \
      automake            \
      g++	                \
      libcurl4-gnutls-dev \
      libpcre++-dev       \
      libtool             \
      libxml2-dev         \
      libyajl-dev         \
      lua5.2-dev          \
      make	              \
      pkgconf             \
      wget            &&  \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install SSDeep
RUN mkdir -p /usr/share/SSDeep && cd /usr/share/SSDeep && \
    wget --quiet "https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz" && \
    tar -xvzf ssdeep-2.14.1.tar.gz && cd /usr/share/SSDeep/ssdeep-2.14.1/ && \
    ./configure && \
    make && make install && make clean

# Download ModSecurity & compile ModSecurity
RUN mkdir -p /usr/share/ModSecurity && cd /usr/share/ModSecurity && \
    wget --quiet "https://github.com/SpiderLabs/ModSecurity/releases/download/v2.9.3/modsecurity-2.9.3.tar.gz" && \
    tar -xvzf modsecurity-2.9.3.tar.gz && cd /usr/share/ModSecurity/modsecurity-2.9.3/ && \
    ./autogen.sh && ./configure && \
    make && make install && make clean

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new -config /usr/share/TLS/openssl.conf -keyout /usr/share/TLS/server.key -out /usr/share/TLS/server.crt

FROM httpd:2.4

ARG SERVERNAME=localhost
ARG SETPROXY=False
ARG SETTLS=False
ARG TLSPUBLICFILE=./server.crt
ARG TLSPRIVATEFILE=./server.key
ARG PROXYLOCATION=http://localhost


RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends --no-install-suggests \
      libcurl3-gnutls     \
      libxml2             \
      libyajl2            && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/modsecurity.d && \
    mkdir -p /var/log/apache2/

COPY --from=build /usr/local/apache2/modules/mod_security2.so                            /usr/local/apache2/modules/mod_security2.so
COPY --from=build /usr/share/ModSecurity/modsecurity-2.9.3/modsecurity.conf-recommended  /etc/modsecurity.d/modsecurity.conf
COPY --from=build /usr/share/ModSecurity/modsecurity-2.9.3/unicode.mapping               /etc/modsecurity.d/unicode.mapping
COPY --from=build /usr/local/lib/libfuzzy.so.2.1.0             		                 /usr/local/lib/libfuzzy.so.2.1.0
COPY --from=build /usr/local/bin/ssdeep               		           	         /usr/local/bin/ssdeep
COPY --from=build /usr/share/TLS/server.key                                              /usr/local/apache2/conf/server.key
COPY --from=build /usr/share/TLS/server.crt                                              /usr/local/apache2/conf/server.crt

RUN ln -s libfuzzy.so.2.1.0 /usr/local/lib/libfuzzy.so && \
	ln -s libfuzzy.so.2.1.0 /usr/local/lib/libfuzzy.so.2 && \
	ldconfig


RUN sed -i -e 's/#LoadModule unique_id_module/LoadModule unique_id_module/g' /usr/local/apache2/conf/httpd.conf && \
	sed -i -e 's/ServerTokens Full/ServerTokens Prod/g' /usr/local/apache2/conf/extra/httpd-default.conf && \
  echo "ErrorLog /var/log/apache2/error.log"                                        >>	/usr/local/apache2/conf/httpd.conf && \
	echo "LoadModule security2_module /usr/local/apache2/modules/mod_security2.so"    >>	/usr/local/apache2/conf/httpd.conf && \
	echo "Include conf/extra/httpd-default.conf"   									                  >>	/usr/local/apache2/conf/httpd.conf && \
	echo "<IfModule security2_module>\nInclude /etc/modsecurity.d/include.conf\n</IfModule>" 	  >>	/usr/local/apache2/conf/httpd.conf && \
  echo "ServerName $SERVERNAME" 												 	                        >> 	/usr/local/apache2/conf/httpd.conf && \
  echo "hello world" > /usr/local/apache2/htdocs/index.html

RUN if [ "$SETTLS" = "True" ]; then echo "setting TLS"; sed -i \
        -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
        -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        conf/httpd.conf; \
	fi

RUN if [ "$SETPROXY" = "True" ]; then echo "setting Proxy"; sed -i \
        -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
		    -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
        conf/httpd.conf; \
		echo "<IfModule proxy_module>\nInclude conf/extra/httpd-proxy.conf\n</IfModule>" >> /usr/local/apache2/conf/httpd.conf; \
    if [ "$SETTLS" = "True" ]; then \
      echo "<ifModule proxy_module>\nSSLProxyEngine on\nProxyPass / $PROXYLOCATION\nProxyPassReverse / $PROXYLOCATION\n</ifModule>" > /usr/local/apache2/conf/extra/httpd-proxy.conf; \
    else \
      echo "<ifModule proxy_module>\nProxyPass / $PROXYLOCATION\nProxyPassReverse / $PROXYLOCATION\n</ifModule>" > /usr/local/apache2/conf/extra/httpd-proxy.conf; \
    fi; \
	fi

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/apache2/bin/apachectl", "-D", "FOREGROUND"]
