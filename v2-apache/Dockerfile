ARG APACHE_VERSION=2.4

FROM httpd:${APACHE_VERSION} as build

ARG MODSEC_VERSION=2.9.5 \
    SSDEEP_VERSION=2.14.1 \
    FUZZY_VERSION=2.1.0

RUN set -eux; \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends --no-install-suggests \
        automake \
        ca-certificates \
        g++ \
        git \
        libapr1-dev \
        libaprutil1-dev \
        libcurl4-gnutls-dev \
        libpcre++-dev \
        libtool \
        libxml2-dev \
        libyajl-dev \
        lua5.2-dev \
        make \
        pkgconf \
        wget

    RUN set -eux; \
    wget --quiet https://github.com/ssdeep-project/ssdeep/releases/download/release-${SSDEEP_VERSION}/ssdeep-${SSDEEP_VERSION}.tar.gz; \
    tar -xzf ssdeep-${SSDEEP_VERSION}.tar.gz; \
    cd ssdeep-${SSDEEP_VERSION}; \
    ./configure; \
    make; \
    make install; \
    make clean

RUN set -eux; \
    git clone https://github.com/SpiderLabs/ModSecurity --branch v${MODSEC_VERSION} --depth 1; \
    cd ModSecurity; \
    ./autogen.sh; \
    ./configure; \
    make; \
    make install; \
    make clean

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY v2-apache/openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new \
    -config /usr/share/TLS/openssl.conf \
    -keyout /usr/share/TLS/server.key \
    -out /usr/share/TLS/server.crt

FROM httpd:${APACHE_VERSION}

ARG MODSEC_VERSION=2.9.5 \
    SSDEEP_VERSION=2.14.1 \
    FUZZY_VERSION=2.1.0

LABEL maintainer="Felipe Zipitria <felipe.zipitria@owasp.org>"

ENV ACCESSLOG=/var/log/apache2/access.log \
    BACKEND=http://localhost:80 \
    BACKEND_WS=ws://localhost:8080 \
    ERRORLOG=/var/log/apache2/error.log \
    H2_PROTOCOLS='h2 http/1.1' \
    LOGLEVEL=warn \
    METRICS_ALLOW_FROM='127.0.0.0/255.0.0.0 ::1/128' \
    METRICS_DENY_FROM='All' \
    METRICSLOG='/dev/null combined' \
    MODSEC_AUDIT_ENGINE="RelevantOnly" \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_LOG_PARTS='ABIJDEFHZ' \
    MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=500000 \
    MODSEC_PCRE_MATCH_LIMIT=500000 \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_LIMIT_ACTION="Reject" \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_REQ_BODY_JSON_DEPTH_LIMIT=512 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_RESP_BODY_LIMIT_ACTION="ProcessPartial" \
    MODSEC_RESP_BODY_MIMETYPE="text/plain text/html text/xml" \
    MODSEC_RULE_ENGINE=on \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_TMP_SAVE_UPLOADED_FILES="on" \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    PERFLOG='/dev/stdout perflogjson env=write_perflog' \
    PORT=80 \
    PROXY_PRESERVE_HOST=on \
    PROXY_SSL_CA_CERT=/etc/ssl/certs/ca-certificates.crt \
    PROXY_SSL_CERT_KEY=/usr/local/apache2/conf/server.key \
    PROXY_SSL_CERT=/usr/local/apache2/conf/server.crt \
    PROXY_SSL_CHECK_PEER_NAME=off \
    PROXY_SSL_VERIFY=none \
    PROXY_SSL=on \
    PROXY_TIMEOUT=60 \
    REMOTEIP_INT_PROXY='10.1.0.0/16' \
    REQ_HEADER_FORWARDED_PROTO='https' \
    SERVER_ADMIN=root@localhost \
    SERVER_NAME=localhost \
    SSL_ENGINE=on \
    SSL_PORT=443 \
    TIMEOUT=60 \
    WORKER_CONNECTIONS=400

RUN set -eux; \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; \
    apt-get update -qq; \
    apt-get install -qq -y --no-install-recommends --no-install-suggests \
        ca-certificates \
        libcurl3-gnutls \
        libxml2 \
        libyajl2; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /etc/modsecurity.d/; \
    mkdir -p /tmp/modsecurity/data; \
    mkdir -p /tmp/modsecurity/upload; \
    mkdir -p /tmp/modsecurity/tmp; \
    chown -R $(awk '/^User/ { print $2;}' /usr/local/apache2/conf/httpd.conf) /tmp/modsecurity; \
    mkdir -p /var/log/apache2/

COPY --from=build /usr/local/apache2/modules/mod_security2.so                  /usr/local/apache2/modules/mod_security2.so
COPY --from=build /usr/local/apache2/ModSecurity/modsecurity.conf-recommended  /etc/modsecurity.d/modsecurity.conf
COPY --from=build /usr/local/apache2/ModSecurity/unicode.mapping               /etc/modsecurity.d/unicode.mapping
COPY --from=build /usr/local/lib/libfuzzy.so.${FUZZY_VERSION}                  /usr/local/lib/libfuzzy.so.${FUZZY_VERSION}
COPY --from=build /usr/local/bin/ssdeep                                        /usr/local/bin/ssdeep
COPY --from=build /usr/share/TLS/server.key                                    /usr/local/apache2/conf/server.key
COPY --from=build /usr/share/TLS/server.crt                                    /usr/local/apache2/conf/server.crt
COPY src/etc/modsecurity.d/*.conf /etc/modsecurity.d/
COPY v2-apache/conf/extra/*.conf /usr/local/apache2/conf/extra/

RUN set -eux; \
    ln -s libfuzzy.so.${FUZZY_VERSION} /usr/local/lib/libfuzzy.so; \
    ln -s libfuzzy.so.${FUZZY_VERSION} /usr/local/lib/libfuzzy.so.2; \
    ldconfig

RUN set -eux; \
    sed -i -E 's|(Listen) [0-9]+|\1 ${PORT}|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|(ServerTokens) Full|\1 Prod|' /usr/local/apache2/conf/extra/httpd-default.conf; \
    sed -i -E 's|#(ServerName) www.example.com:80|\1 ${SERVER_NAME}|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule unique_id_module)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule rewrite_module modules/mod_rewrite.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule proxy_module modules/mod_proxy.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule proxy_http_module modules/mod_proxy_http.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule remoteip_module modules/mod_remoteip.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule socache_shmcb_module modules/mod_socache_shmcb.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule ssl_module modules/mod_ssl.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(LoadModule http2_module modules/mod_http2.so)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(Include conf/extra/httpd-default.conf)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(Include conf/extra/httpd-proxy.conf)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(Include conf/extra/httpd-ssl.conf)|\1|' /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|#(Include conf/extra/httpd-vhosts.conf)|\1|' /usr/local/apache2/conf/httpd.conf; \
    echo 'Include conf/extra/httpd-locations.conf' >> /usr/local/apache2/conf/httpd.conf; \
    echo 'Include conf/extra/httpd-modsecurity.conf' >> /usr/local/apache2/conf/httpd.conf; \
    sed -i -E 's|(MaxRequestWorkers[ ]*)[0-9]*|\1${WORKER_CONNECTIONS}|' /usr/local/apache2/conf/extra/httpd-mpm.conf; \
    chgrp -R 0 /var/log/ /usr/local/apache2/; \
    chmod -R g=u /var/log/ /usr/local/apache2/

# Use httpd-foreground from upstream
