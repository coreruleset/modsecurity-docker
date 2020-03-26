FROM nginx:1.17.9 as build

LABEL version="3.0.4"
LABEL maintainer="Chaim Sanders <chaim.sanders@gmail.com>"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      automake \
      cmake \
      doxygen \
      g++ \
      git \
      libcurl4-gnutls-dev \
      libgeoip-dev \
      liblua5.3-dev \
      libpcre++-dev \
      libtool \
      libxml2-dev \
      make \
      ruby \
      wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /sources

RUN git clone https://github.com/LMDB/lmdb --branch LMDB_0.9.23 --depth 1 \
 && make -C lmdb/libraries/liblmdb install

RUN git clone https://github.com/lloyd/yajl --branch 2.1.0 --depth 1 \
 && cd yajl \
 && ./configure \
 && make install

RUN wget --quiet https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz \
 && tar -xvzf ssdeep-2.14.1.tar.gz \
 && cd ssdeep-2.14.1 \
 && ./configure \
 && make install

RUN git clone https://github.com/SpiderLabs/ModSecurity --branch v3.0.4 --depth 1 \
 && cd ModSecurity \
 && ./build.sh \
 && git submodule init \
 && git submodule update \
 && ./configure --with-yajl=/sources/yajl/build/yajl-2.1.0/ \
 && make install

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY v3-nginx/openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new \
      -config /usr/share/TLS/openssl.conf \
      -keyout /usr/share/TLS/server.key \
      -out /usr/share/TLS/server.crt

FROM nginx:1.17.9

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV ACCESSLOG=/var/log/nginx/access.log \
    BACKEND=http://localhost:80 \
    DNS_SERVER= \
    ERRORLOG=/var/log/nginx/error.log \
    LOGLEVEL=warn \
    METRICS_ALLOW_FROM='127.0.0.0/24' \
    METRICS_DENY_FROM='all' \
    METRICSLOG=/dev/null \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000 \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_RULE_ENGINE=on \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    PORT=80 \
    PROXY_TIMEOUT=60s \
    PROXY_SSL_CERT_KEY=/etc/nginx/conf/server.key \
    PROXY_SSL_CERT=/etc/nginx/conf/server.crt \
    PROXY_SSL_VERIFY=off \
    SERVER_NAME=localhost \
    SSL_PORT=443 \
    TIMEOUT=60s \
    WORKER_CONNECTIONS=1024 \
    LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      gcc \
      git \
      libcurl4-gnutls-dev \
      liblua5.3-dev \
      libpcre++-dev \
      libxml2-dev \
      make \
      wget \
      moreutils \
      zlib1g-dev && \
      rm -rf /var/lib/apt/lists/* && \
      apt-get clean \
 && git clone https://github.com/SpiderLabs/ModSecurity-nginx --branch v1.0.1 --depth 1 \
 && mkdir /etc/nginx/ssl/

COPY --from=build /usr/local/modsecurity/ /usr/local/modsecurity/
COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/share/TLS/server.key /etc/nginx/conf/server.key
COPY --from=build /usr/share/TLS/server.crt /etc/nginx/conf/server.crt
COPY src/etc/modsecurity.d/*.conf /etc/modsecurity.d/
COPY v3-nginx/conf.d/*.conf /etc/nginx/conf.d/
COPY v3-nginx/nginx.conf /etc/nginx/
COPY v3-nginx/docker-entrypoint.sh /

RUN version="$(/usr/sbin/nginx -v 2>&1 | cut -d '/' -f 2)" \
 && wget --quiet http://nginx.org/download/nginx-"$version".tar.gz \
 && tar -xvzf nginx-"$version".tar.gz \
 && cd /nginx-"$version" \
 && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx \
 && make modules \
 && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/ \
 && wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
    -O /etc/modsecurity.d/modsecurity.conf \
 && wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping \
    -O /etc/modsecurity.d/unicode.mapping

RUN chgrp -R 0 /var/cache/nginx/ /var/log/ /var/run/ /usr/share/nginx/ /etc/nginx/ /etc/modsecurity.d/ \
 && chmod -R g=u /var/cache/nginx/ /var/log/ /var/run/ /usr/share/nginx/ /etc/nginx/ /etc/modsecurity.d/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
