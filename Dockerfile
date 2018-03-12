FROM alpine:3.7 as build

# Install Prereqs
RUN apk --update add \
     alpine-sdk      \
     apache2         \
     apache2-dev     \
     autoconf        \
     automake        \
     ca-certificates \
     file            \
     libtool         \
     libxml2-dev     \
     linux-headers   \
     pcre-dev        \
     wget 

# Download ModSecurity
RUN set -eux \
  && mkdir -p /usr/share/ModSecurity && cd /usr/share/ModSecurity \
  && wget --quiet "https://github.com/SpiderLabs/ModSecurity/releases/download/v2.9.2/modsecurity-2.9.2.tar.gz" \
  && tar -xzf modsecurity-2.9.2.tar.gz

# Install ModSecurity
RUN set -eux && \
  cd /usr/share/ModSecurity/modsecurity-2.9.2/ \
  && sh autogen.sh && ./configure \
  && make && make install && make clean

FROM alpine:3.7 

RUN apk --update add \
     apache2         \
     apr-util        \
     ca-certificates \
     libxml2         \
    && rm -f /var/cache/apk/* \
    && mkdir -p /etc/apache2/modsecurity.d /run/apache2

COPY ./httpd.conf /etc/apache2/httpd.conf
COPY --from=build /usr/share/ModSecurity/modsecurity-2.9.2/modsecurity.conf-recommended  /etc/apache2/modsecurity.d/modsecurity.conf
COPY --from=build /usr/share/ModSecurity/modsecurity-2.9.2/unicode.mapping  /etc/apache2/modsecurity.d/unicode.mapping
COPY --from=build /usr/lib/apache2/mod_security2.so /usr/lib/apache2/

RUN sed -i 's#^\(\s*SecAuditLog\)\s*\S*$#\1 /proc/self/fd/2#g' /etc/apache2/modsecurity.d/modsecurity.conf

WORKDIR /etc/apache2

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
