FROM nginx:1 as build

LABEL version="3.0.3"
LABEL maintainer="Chaim Sanders <chaim.sanders@gmail.com>"

RUN apt-get update \
 && apt-get install -y \
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
      wget

RUN git clone https://github.com/LMDB/lmdb --branch LMDB_0.9.23 --depth 1 \
 && cd lmdb/libraries/liblmdb \
 && make \
 && make install

RUN git clone https://github.com/lloyd/yajl --branch 2.1.0 --depth 1 \
 && cd yajl \
 && ./configure \
 && make \
 && make install

RUN wget --quiet https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz \
 && tar -xvzf ssdeep-2.14.1.tar.gz \
 && cd ssdeep-2.14.1 \
 && ./configure \
 && make \
 && make install

RUN git clone https://github.com/SpiderLabs/ModSecurity --branch v3.0.3 --depth 1 \
 && cd ModSecurity \
 && ./build.sh \
 && git submodule init \
 && git submodule update \
 && ./configure \
 && make \
 && make install

# Generate self-signed certificates (if needed)
RUN mkdir -p /usr/share/TLS
COPY openssl.conf /usr/share/TLS
RUN openssl req -x509 -days 365 -new \
      -config /usr/share/TLS/openssl.conf \
      -keyout /usr/share/TLS/server.key \
      -out /usr/share/TLS/server.crt

FROM nginx:1

ARG SERVERNAME=localhost
ARG SETPROXY=False
ARG SETTLS=False
ARG PROXYLOCATION=www.example.com

RUN apt-get update \
 && apt-get install -y \
      gcc \
      git \
      libcurl4-gnutls-dev \
      liblua5.3-dev \
      libpcre++-dev \
      libxml2-dev \
      make \
      wget \
      zlib1g-dev

RUN git clone https://github.com/SpiderLabs/ModSecurity-nginx --branch v1.0.1 --depth 1

RUN mkdir /etc/nginx/ssl/

COPY --from=build /usr/local/modsecurity/ /usr/local/modsecurity/
COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/share/TLS/server.key /etc/nginx/conf/server.key
COPY --from=build /usr/share/TLS/server.crt /etc/nginx/conf/server.crt
COPY ./tls.conf /etc/nginx/conf.d/tls.conf.disabled

RUN export version=$(echo `/usr/sbin/nginx -v 2>&1` | cut -d '/' -f 2) && \
    wget --quiet http://nginx.org/download/nginx-$version.tar.gz && \
    tar -xvzf nginx-$version.tar.gz && \
    cd /nginx-$version && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

RUN mkdir /etc/modsecurity.d && \
    cd /etc/modsecurity.d && \
    echo "include \"/etc/modsecurity.d/modsecurity.conf\"" > include.conf && \
    wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended && \
    mv modsecurity.conf-recommended modsecurity.conf && \
    wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping

RUN sed -i '1iload_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf && \
    sed -i -e 's/http {/http {\n    modsecurity on;\n    modsecurity_rules_file \/etc\/modsecurity.d\/include.conf;\n/g' /etc/nginx/nginx.conf

ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib

RUN apt-get install -y vim
RUN echo $SERVERNAME
RUN sed -i -E "s/server_name .*;/server_name $SERVERNAME;/g" /etc/nginx/conf.d/default.conf

RUN if [ "$SETTLS" = "True" ]; then \
      echo "setting TLS"; \
      mv /etc/nginx/conf.d/tls.conf.disabled /etc/nginx/conf.d/tls.conf; \
      sed -i -E 's/server_name .*;/server_name $SERVERNAME;/g' /etc/nginx/conf.d/tls.conf; \
    fi

RUN if [ "$SETPROXY" = "True" ]; then \
      echo "setting Proxy"; \
      sed -i -e "s/location \/ {/resolver 8.8.8.8 valid=5s;\n    set \$upstream $PROXYLOCATION;\n    location \/ {\n\
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
          sed -i -e "s/location \/ {/resolver 8.8.8.8 valid=5s;\n    set \$upstream $PROXYLOCATION;\n    location \/ {\n\
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

CMD ["nginx", "-g", "daemon off;"]
