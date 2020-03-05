FROM httpd:2.4 as build

LABEL version="2.9.3"
LABEL maintainer="Chaim Sanders <chaim.sanders@gmail.com>"

RUN apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests \
      automake \
      ca-certificates \
      g++ \
      git \
      libcurl4-gnutls-dev \
      libpcre++-dev \
      libtool \
      libxml2-dev \
      libyajl-dev \
      lua5.2-dev \
      make \
      pkgconf \
      wget

RUN wget --quiet https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz \
 && tar -xvzf ssdeep-2.14.1.tar.gz \
 && cd ssdeep-2.14.1 \
 && ./configure \
 && make \
 && make install \
 && make clean

RUN git clone https://github.com/SpiderLabs/ModSecurity --branch v2.9.3 --depth 1 \
 && cd ModSecurity \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && make clean

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY v2-apache/openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new \
      -config /usr/share/TLS/openssl.conf \
      -keyout /usr/share/TLS/server.key \
      -out /usr/share/TLS/server.crt

FROM httpd:2.4

ARG SETPROXY=True
ARG SETTLS=True
ARG TLSPUBLICFILE=./server.crt
ARG TLSPRIVATEFILE=./server.key
ENV PROXYLOCATION=localhost:80 \
    SERVERNAME=localhost \
    ERRORLOG=/var/log/apache2/error.log \
    ACCESSLOG=/var/log/apache2/access.log \
    APACHE_TIMEOUT=60 \
    LOGLEVEL=warn \
    USER=daemon \
    GROUP=daemon \
    SERVERADMIN=root@localhost \
    PORT=80 \
    MODSEC_RULE_ENGINE=on \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq \
 && apt-get install -qq -y --no-install-recommends --no-install-suggests \
      libcurl3-gnutls \
      libxml2 \
      libyajl2 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /etc/modsecurity.d \
 && mkdir -p /var/log/apache2/

COPY --from=build /usr/local/apache2/modules/mod_security2.so                  /usr/local/apache2/modules/mod_security2.so
COPY --from=build /usr/local/apache2/ModSecurity/modsecurity.conf-recommended  /etc/modsecurity.d/modsecurity.conf
COPY --from=build /usr/local/apache2/ModSecurity/unicode.mapping               /etc/modsecurity.d/unicode.mapping
COPY --from=build /usr/local/lib/libfuzzy.so.2.1.0                             /usr/local/lib/libfuzzy.so.2.1.0
COPY --from=build /usr/local/bin/ssdeep                                        /usr/local/bin/ssdeep
COPY --from=build /usr/share/TLS/server.key                                    /usr/local/apache2/conf/server.key
COPY --from=build /usr/share/TLS/server.crt                                    /usr/local/apache2/conf/server.crt
COPY src/etc/modsecurity.d/*.conf /etc/modsecurity.d/
COPY v2-apache/conf/extra/httpd-modsecurity.conf /usr/local/apache2/conf/extra/

RUN ln -s libfuzzy.so.2.1.0 /usr/local/lib/libfuzzy.so \
 && ln -s libfuzzy.so.2.1.0 /usr/local/lib/libfuzzy.so.2 \
 && ldconfig

RUN sed -i -E 's|(Listen) [0-9]+|\1 ${PORT}|' /usr/local/apache2/conf/httpd.conf \
 && sed -i -E 's|(ServerTokens) Full|\1 Prod|' /usr/local/apache2/conf/extra/httpd-default.conf \
 && sed -i -E 's|#(Include conf/extra/httpd-default.conf)|\1|' /usr/local/apache2/conf/httpd.conf \
 && sed -i -E 's|#(ServerName) www.example.com:80|\1 ${SERVERNAME}|' /usr/local/apache2/conf/httpd.conf \
 && sed -i -E 's|#(LoadModule unique_id_module)|\1|' /usr/local/apache2/conf/httpd.conf \
 && echo 'Include conf/extra/httpd-modsecurity.conf' >> /usr/local/apache2/conf/httpd.conf

RUN if [ "$SETTLS" = "True" ]; then \
      echo "setting TLS"; \
      sed -i \
        -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
        -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        conf/httpd.conf; \
      sed -i \
        -e 's/^ServerName www\.example\.com:443/ServerName \${SERVERNAME}/' \
        -e 's/^CustomLog \/proc\/self\/fd\/1 \\/CustomLog		\${ACCESSLOG} extended/' \
        -e 's/"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\"%r\\" %b"//' \
        -e 's/ErrorLog \/proc\/self\/fd\/2/ErrorLog		\${ERRORLOG}/' \
        conf/extra/httpd-ssl.conf; \
    fi

RUN if [ "$SETPROXY" = "True" ]; then \
      echo "setting Proxy"; \
      sed -i \
        -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
        conf/httpd.conf; \
      echo "<IfModule proxy_module>\nInclude conf/extra/httpd-proxy.conf\n</IfModule>" >> /usr/local/apache2/conf/httpd.conf; \
      if [ "$SETTLS" = "True" ]; then \
        echo "<ifModule proxy_module>\nSSLProxyEngine on\nProxyPass / \${PROXYLOCATION}\nProxyPassReverse / \${PROXYLOCATION}\n</ifModule>" > /usr/local/apache2/conf/extra/httpd-proxy.conf; \
      else \
        echo "<ifModule proxy_module>\nProxyPass / \${PROXYLOCATION}\nProxyPassReverse / \${PROXYLOCATION}\n</ifModule>" > /usr/local/apache2/conf/extra/httpd-proxy.conf; \
      fi; \
    fi

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/apache2/bin/apachectl", "-D", "FOREGROUND"]
