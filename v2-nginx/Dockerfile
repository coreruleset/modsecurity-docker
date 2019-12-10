FROM nginx:1 as build
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

ARG MODSEC_VERSION='2.9.3'

# Install Prereqs
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends --no-install-suggests \
      apache2-dev         \
      automake            \
      ca-certificates     \
      libssl-dev          \
      libcurl4-gnutls-dev \
      libpcre++-dev       \
      libtool             \
      libxml2-dev         \
      libyajl-dev         \
      lua5.2-dev          \
      pkgconf             \
      ssdeep              \
      zlib1g-dev          \
      wget             && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

# Download ModSecurity
RUN cd /opt && \
    wget  --quiet https://github.com/SpiderLabs/ModSecurity/releases/download/v$MODSEC_VERSION/modsecurity-$MODSEC_VERSION.tar.gz && \
    tar -xzf modsecurity-$MODSEC_VERSION.tar.gz

# Install ModSecurity
RUN cd /opt/modsecurity-$MODSEC_VERSION/ && \
    sh autogen.sh && \
    ./configure --enable-standalone-module && \
    make && make install && make clean

# Move Files
RUN cd /opt/modsecurity-$MODSEC_VERSION/ && \
    mkdir -p /etc/modsecurity.d && \
    mv modsecurity.conf-recommended  /etc/modsecurity.d/modsecurity.conf && \
    mv unicode.mapping /etc/modsecurity.d/ && \
    printf "include modsecurity.conf" > /etc/modsecurity.d/includes.conf && \
    sed -i '1iload_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf && \
    sed -i '1iload_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf && \
    sed -i -e 's/http {/http {\n    modsecurity on;\n    modsecurity_rules_file \/etc\/modsecurity.d\/include.conf;\n/g' /etc/nginx/nginx.conf

####################

FROM nginx:1

COPY --from=build /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /etc/modsecurity.d /etc/modsecurity.d
COPY --from=build /usr/local/modsecurity/lib/standalone.so /etc/nginx/modules/ngx_http_modsecurity_module.so

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends --no-install-suggests \
      libapr1         \
      libaprutil1     \
      libc6           \
      libcurl3-gnutls \
      liblua5.2-0     \
      libxml2         \
      libyajl2     &&  \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
