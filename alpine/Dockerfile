FROM httpd:2.4-alpine

USER root
# Install Prereqs
RUN set -eux && \
  apk --update add --no-cache --virtual .build-deps \
    alpine-sdk \
    autoconf \
    automake \
    ca-certificates \
    file \
    libtool \
    libxml2-dev \
    linux-headers \
    pcre-dev \
    wget && \
  update-ca-certificates


# Download ModSecurity
RUN set -eux && \
  mkdir -p /usr/share/ModSecurity && \
  cd /usr/share/ModSecurity && \
  wget --quiet "https://github.com/SpiderLabs/ModSecurity/releases/download/v2.9.2/modsecurity-2.9.2.tar.gz" && \
  tar -xvzf modsecurity-2.9.2.tar.gz


# Install ModSecurity
RUN set -eux && \
  cd /usr/share/ModSecurity/modsecurity-2.9.2/ && \
  sh autogen.sh && \
  ./configure && \
  make && \
  make install && \
  make clean

RUN set -eux && \
  ln -s /usr/local/apache2/conf /etc/httpd && \
  cd /usr/share/ModSecurity/modsecurity-2.9.2/ && \
  mkdir -p /etc/httpd/modsecurity.d && \
  mv modsecurity.conf-recommended  /etc/httpd/modsecurity.d/modsecurity.conf && \
  sed -i 's#^\(\s*SecAuditLog\)\s*\S*$#\1 /proc/self/fd/2#g' /etc/httpd/modsecurity.d/modsecurity.conf && \
  mv unicode.mapping /etc/httpd/modsecurity.d/ && \
  mkdir -p /etc/httpd/conf.d && \
  printf "LoadModule security2_module modules/mod_security2.so\nLoadModule unique_id_module modules/mod_unique_id.so\nInclude conf/modsecurity.d/*.conf" > /etc/httpd/conf.d/10-modsecurty.conf && \
  echo "Include /etc/httpd/conf.d/*.conf" >> /etc/httpd/httpd.conf


RUN runDeps="$runDeps $( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
    apk add --virtual .httpd-rundeps $runDeps; \
    apk del .build-deps

WORKDIR /etc/httpd
