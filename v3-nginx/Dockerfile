ARG NGINX_VERSION="1.20.2"

FROM nginx:${NGINX_VERSION} as build

ARG MODSEC_VERSION=3.0.7 \
    YAJL_VERSION=2.1.0 \
    FUZZY_VERSION=2.1.0 \
    LMDB_VERSION=0.9.29 \
    SSDEEP_VERSION=2.14.1

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        pkg-config \
        zlib1g-dev; \
     apt-get clean; \
     rm -rf /var/lib/apt/lists/*

WORKDIR /sources

RUN set -eux; \
    git clone https://github.com/LMDB/lmdb --branch LMDB_${LMDB_VERSION} --depth 1; \
    make -C lmdb/libraries/liblmdb install; \
    strip /usr/local/lib/liblmdb*.so*

RUN set -eux; \
    git clone https://github.com/lloyd/yajl --branch ${YAJL_VERSION} --depth 1; \
    cd yajl; \
    ./configure; \
    make install; \
    strip /usr/local/lib/libyajl*.so*

RUN set -eux; \
    curl -sSL https://github.com/ssdeep-project/ssdeep/releases/download/release-${SSDEEP_VERSION}/ssdeep-${SSDEEP_VERSION}.tar.gz -o ssdeep-${SSDEEP_VERSION}.tar.gz; \
    tar -xvzf ssdeep-${SSDEEP_VERSION}.tar.gz; \
    cd ssdeep-${SSDEEP_VERSION}; \
    ./configure; \
    make install; \
    strip /usr/local/lib/libfuzzy*.so*

RUN set -eux; \
    git clone https://github.com/SpiderLabs/ModSecurity --branch v"${MODSEC_VERSION}" --depth 1; \
    cd ModSecurity; \
    ./build.sh; \
    git submodule init; \
    git submodule update; \
    ./configure --with-yajl=/sources/yajl/build/yajl-${YAJL_VERSION}/ --with-geoip; \
    make install; \
    strip /usr/local/modsecurity/lib/lib*.so*

# We use master
RUN set -eux; \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git; \
    curl -sSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz; \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
    cd ./nginx-${NGINX_VERSION}; \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx; \
    make modules; \
    strip objs/ngx_http_modsecurity_module.so; \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/; \
    mkdir /etc/modsecurity.d; \
    curl -sSL https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
         -o /etc/modsecurity.d/modsecurity.conf; \
    curl -sSL https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping \
         -o /etc/modsecurity.d/unicode.mapping

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY v3-nginx/openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new \
    -config /usr/share/TLS/openssl.conf \
    -keyout /usr/share/TLS/server.key \
    -out /usr/share/TLS/server.crt

# Generate/Download Diffie-Hellman parameter files
RUN openssl dhparam -out /usr/share/TLS/dhparam-1024.pem 1024
RUN curl -sSL https://ssl-config.mozilla.org/ffdhe2048.txt -o /usr/share/TLS/dhparam-2048.pem
RUN curl -sSL https://ssl-config.mozilla.org/ffdhe4096.txt -o /usr/share/TLS/dhparam-4096.pem

FROM nginx:${NGINX_VERSION}

ARG MODSEC_VERSION=3.0.6 \
    YAJL_VERSION=2.1.0 \
    FUZZY_VERSION=2.1.0 \
    LMDB_VERSION=0.9.29 \
    SSDEEP_VERSION=2.14.1

LABEL maintainer="Felipe Zipitria <felipe.zipitria@owasp.org>"

ENV ACCESSLOG=/var/log/nginx/access.log \
    BACKEND=http://localhost:80 \
    DNS_SERVER= \
    ERRORLOG=/var/log/nginx/error.log \
    LOGLEVEL=warn \
    METRICS_ALLOW_FROM='127.0.0.0/24' \
    METRICS_DENY_FROM='all' \
    METRICSLOG=/dev/null \
    MODSEC_AUDIT_ENGINE="RelevantOnly" \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_LOG_PARTS='ABIJDEFHZ' \
    MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_DEFAULT_PHASE1_ACTION="phase:1,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_DEFAULT_PHASE2_ACTION="phase:2,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000 \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_LIMIT_ACTION="Reject" \
    MODSEC_REQ_BODY_JSON_DEPTH_LIMIT=512 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_RESP_BODY_LIMIT_ACTION="ProcessPartial" \
    MODSEC_RESP_BODY_MIMETYPE="text/plain text/html text/xml" \
    MODSEC_RULE_ENGINE=on \
    MODSEC_STATUS_ENGINE="Off" \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_TMP_SAVE_UPLOADED_FILES="on" \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    PORT=80 \
    NGINX_ALWAYS_TLS_REDIRECT=off \
    PROXY_TIMEOUT=60s \
    PROXY_SSL_CERT=/etc/nginx/conf/server.crt \
    PROXY_SSL_CERT_KEY=/etc/nginx/conf/server.key \
    PROXY_SSL_DH_BITS=2048 \
    PROXY_SSL_PROTOCOLS="TLSv1.2 TLSv1.3" \
    PROXY_SSL_CIPHERS="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" \
    PROXY_SSL_PREFER_CIPHERS=off \
    PROXY_SSL_VERIFY=off \
    PROXY_SSL_OCSP_STAPLING=off \
    SERVER_NAME=localhost \
    SSL_PORT=443 \
    TIMEOUT=60s \
    WORKER_CONNECTIONS=1024 \
    LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib \
    NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libcurl4-gnutls-dev \
        liblua5.3 \
        libxml2 \
        moreutils; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get clean; \
    mkdir /etc/nginx/ssl; \
    mkdir -p /tmp/modsecurity/data; \
    mkdir -p /tmp/modsecurity/upload; \
    mkdir -p /tmp/modsecurity/tmp; \
    mkdir -p /usr/local/modsecurity; \
    chown -R nginx:nginx /tmp/modsecurity

COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC_VERSION} /usr/local/modsecurity/lib/
COPY --from=build /usr/local/lib/libfuzzy.so.${FUZZY_VERSION} /usr/local/lib/
COPY --from=build /etc/nginx/modules/ngx_http_modsecurity_module.so /etc/nginx/modules/ngx_http_modsecurity_module.so
COPY --from=build /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/
COPY --from=build /usr/local/lib/liblmdb.so /usr/local/lib/
COPY --from=build /usr/share/TLS/server.key /etc/nginx/conf/server.key
COPY --from=build /usr/share/TLS/server.crt /etc/nginx/conf/server.crt
COPY --from=build /usr/share/TLS/dhparam-* /etc/ssl/certs/
COPY --from=build /etc/modsecurity.d/unicode.mapping /etc/modsecurity.d/unicode.mapping
COPY --from=build /etc/modsecurity.d/modsecurity.conf /etc/modsecurity.d/modsecurity.conf
COPY v3-nginx/templates /etc/nginx/templates/
COPY src/etc/modsecurity.d/modsecurity-override.conf /etc/nginx/templates/modsecurity.d/modsecurity-override.conf.template
COPY src/etc/modsecurity.d/setup.conf /etc/nginx/templates/modsecurity.d/setup.conf.template
COPY v3-nginx/docker-entrypoint.d/*.sh /docker-entrypoint.d/

RUN set -eux; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3; \
    ln -s /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so; \
    ln -s /usr/local/lib/libfuzzy.so.${FUZZY_VERSION} /usr/local/lib/libfuzzy.so; \
    ln -s /usr/local/lib/libfuzzy.so.${FUZZY_VERSION} /usr/local/lib/libfuzzy.so.2; \
    ln -s /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/libyajl.so; \
    ln -s /usr/local/lib/libyajl.so.${YAJL_VERSION} /usr/local/lib/libyajl.so.2; \
    chgrp -R 0 /var/cache/nginx/ /var/log/ /var/run/ /usr/share/nginx/ /etc/nginx/ /etc/modsecurity.d/; \
    chmod -R g=u /var/cache/nginx/ /var/log/ /var/run/ /usr/share/nginx/ /etc/nginx/ /etc/modsecurity.d/

