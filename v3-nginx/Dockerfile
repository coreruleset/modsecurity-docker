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
      wget && \
      rm -rf /var/lib/apt/lists/* && \
      apt-get clean

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
 && ./configure \
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

ARG SETPROXY=False
ARG SETTLS=False
ENV SERVERNAME=localhost \
    PROXYLOCATION=localhost:80 \
    NGINX_KEEPALIVE_TIMEOUT=60s \
    ERRORLOG=/var/log/nginx/error.log \
    LOGLEVEL=warn \
    USER=nginx \
    PORT=80 \
    WORKER_CONNECTIONS=1024 \
    MODSEC_RULE_ENGINE=on \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000

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
      apt-get clean

RUN git clone https://github.com/SpiderLabs/ModSecurity-nginx --branch v1.0.1 --depth 1

RUN mkdir /etc/nginx/ssl/

COPY --from=build /usr/local/modsecurity/ /usr/local/modsecurity/
COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/share/TLS/server.key /etc/nginx/conf/server.key
COPY --from=build /usr/share/TLS/server.crt /etc/nginx/conf/server.crt
COPY ./v3-nginx/tls.conf /etc/nginx/conf.d/tls.conf.disabled
COPY src/etc/modsecurity.d/*.conf /etc/modsecurity.d/
COPY v3-nginx/conf.d/default.conf /etc/nginx/conf.d/
COPY v3-nginx/nginx.conf /etc/nginx/
COPY v3-nginx/docker-entrypoint.sh /

RUN version="$(/usr/sbin/nginx -v 2>&1 | cut -d '/' -f 2)" && \
    wget --quiet http://nginx.org/download/nginx-"$version".tar.gz && \
    tar -xvzf nginx-"$version".tar.gz && \
    cd /nginx-"$version" && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

RUN wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
    -o /etc/modsecurity.d/modsecurity.conf && \
    wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping \
    -o /etc/modsecurity.d/unicode.mapping

ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib

RUN if [ "$SETTLS" = "True" ]; then \
      echo "setting TLS"; \
      mv /etc/nginx/conf.d/tls.conf.disabled /etc/nginx/conf.d/tls.conf; \
      sed -i -E "s/server_name .*;/server_name $SERVERNAME;/g" /etc/nginx/conf.d/tls.conf; \
    fi

RUN if [ "$SETPROXY" = "True" ]; then \
      echo "setting Proxy"; \
      sed -i -e "s/location \/ {/resolver 8.8.8.8 valid=5s;\n    set \$upstream \$PROXYLOCATION;\n    location \/ {\n\
        proxy_set_header Host \$upstream;\n\
        proxy_set_header X-Forwarded-Proto \$scheme;\n\
        proxy_pass_header Authorization;\n\
        proxy_pass http:\/\/\$upstream;\n\
        proxy_set_header X-Real-IP \$remote_addr;\n\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Connection \"\";\n\
        proxy_buffering off;\n\
        client_max_body_size 0;\n\
        proxy_read_timeout 36000s;\n\
        proxy_redirect off; \
      	/g" /etc/nginx/conf.d/default.conf; \
        if [ "$SETTLS" = "True" ]; then \
          sed -i -e "s/location \/ {/resolver 8.8.8.8 valid=5s;\n    set \$upstream \$PROXYLOCATION;\n    location \/ {\n\
            proxy_set_header Host \$upstream;\n\
            proxy_set_header X-Forwarded-Proto \$scheme;\n\
            proxy_pass_header Authorization;\n\
            proxy_pass https:\/\/\$upstream;\n\
            proxy_set_header X-Real-IP \$remote_addr;\n\
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\
            proxy_http_version 1.1;\n\
            proxy_set_header Connection \"\";\n\
            proxy_buffering off;\n\
            client_max_body_size 0;\n\
            proxy_read_timeout 36000s;\n\
            proxy_redirect off; \
          	/g" /etc/nginx/conf.d/tls.conf; \
        fi \
  fi

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
