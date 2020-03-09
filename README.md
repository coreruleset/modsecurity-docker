# ModSecurity Docker Image

[![dockeri.co](http://dockeri.co/image/owasp/modsecurity)](https://hub.docker.com/r/owasp/modsecurity/)

[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2FCRS-support%2Fmodsecurity-docker%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/CRS-support/modsecurity-docker/goto?ref=master
) [![GitHub issues](https://img.shields.io/github/issues-raw/CRS-support/modsecurity-docker.svg)](https://github.com/CRS-support/modsecurity-docker/issues
) [![GitHub PRs](https://img.shields.io/github/issues-pr-raw/CRS-support/modsecurity-docker.svg)](https://github.com/CRS-support/modsecurity-docker/pulls
) [![License](https://img.shields.io/github/license/CRS-support/modsecurity-docker.svg)](https://github.com/CRS-support/modsecurity-docker/blob/master/LICENSE)

## Supported tags and respective `Dockerfile` links

* `3`, `3.0`, `3.0.4` ([master/v3-nginx/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/master/v3-nginx/Dockerfile)) – *last stable ModSecurity v3 on Nginx 1.17 official base image*
* `3.0.3-nginx`,  `3.0-nginx`,`3-nginx`, `latest` ([3.0/nginx/nginx/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v3/nginx-nginx/Dockerfile))
* `3.0.3-apache`, `3.0-apache`, `3-apache` ([3.0/apache/httpd/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v3/apache-apache/Dockerfile))
* `2`, `2.9`, `2.9.3` ([master/v2-apache/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/master/v2-apache/Dockerfile)) – *last stable ModSecurity v2 on Apache 2.4 official base image*
* `2.9.3-apache`,`2.9-apache`, `2-apache` ([2.9/apache/httpd/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/apache-apache/Dockerfile))
* `2.9.3-nginx`, `2.9-nginx`, `2-nginx` (2.9/nginx/nginx/Dockerfile)
* `2.9-apache-ubuntu` ([2.9/apache/ubuntu/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-apache/Dockerfile))
* `2.9-nginx-ubuntu` ([2.9/nginx/ubuntu/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-nginx/Dockerfile))

## Quick reference

* **Where to get help**

   [The CRS-Support Docker Repo](https://github.com/CRS-support/modsecurity-docker), [The Core Rule Set Slack Channel](https://join.slack.com/t/owasp/shared_invite/enQtNjExMTc3MTg0MzU4LTViMDg1MmJiMzMwZGUxZjgxZWQ1MTE0NTBlOTBhNjhhZDIzZTZiNmEwOTJlYjdkMzAxMGVhNDkwNDNiNjZiOWQ) (#coreruleset on owasp.slack.com), or [Stack Overflow](https://stackoverflow.com/questions/tagged/mod-security)

* **Where to file issues**

    [The CRS-Support Docker Repo](https://github.com/CRS-support/modsecurity-docker)

* **Maintained By**

   The OWASP Core Rule Set maintainers

## What is ModSecurity

ModSecurity is an open source, cross platform Web Application Firewall (WAF) engine for Apache, IIS and Nginx. It has a robust event-based programming language which provides protection from a range of attacks against web applications and allows for HTTP traffic monitoring, logging and real-time analysis.

## How to use this image

This image only contains ModSecurity built from the code provided on the [ModSecurity Github Repo](https://github.com/SpiderLabs/ModSecurity). **THE CORE RULE SET IS NOT PROVIDED IN THIS IMAGE**, but it should not be hard to extend. On the other hand, **IF YOU WANT MODSECURITY WITH THE CORE RULE SET please visit the [OWASP Core Rule Set (CRS) DockerHub Repo](https://hub.docker.com/r/owasp/modsecurity-crs/)**.

1. Create a Dockerfile in your project and copy your code into container.

   ```
   FROM modsecurity:2-apache
   COPY ./public-html/ .
   ```

2. run the commands to build and run the Docker image.
   ```
   $ docker build -t my-modsec .
   $ docker run -p 8080:80 my-modsec
   ```

3. Visit http://localhost:8080 and your page.

### TLS/HTTPS

If you want to run your web traffic over TLS you can simply set the SETTLS argument to true when using Docker build. Note: This will use self signed certificates, to use your own certificates (recommended) COPY or mount (-v) your server.crt and server.key into /usr/local/apache2/conf/. Please remember you'll need to forward the HTTPS port

```
$docker build  --build-arg SETTLS=True -t my-modsec .
$docker run -p 8443:443 my-modsec
```

### Proxying

ModSecurity is often used as a reverse proxy. This allows one to use ModSecurity without modifying the webserver hosting the underlying application (and also protect web servers that modsecurity cannot currently embedd into). To set proxying one must set SETPROXY to True and provide the location of the Proxy via the BACKEND environment variable. Note: if you are going to be proxying to a HTTPS site, you'll need to set SETTLS to true also.

```
$docker build --build-arg SETPROXY=True -t my-modsec .
$ docker run -p 8080:80 -e BACKEND=http://example.com my-modsec
```

### ServerName

It is often convenient to set your servername. to do this simply use the SERVER_NAME environment variable passed to docker run. By default the servername provided is localhost.
```
$ docker build -t modsec .
$ docker run -p 8080:80 -e SERVER_NAME=myhost my-modsec
```

### Apache ENV Variables

* ACCESSLOG - A string value indicating the location of the custom log file (Default: '/var/log/apache2/access.log')
* BACKEND - A string indicating the partial URL for the remote server of the `ProxyPass` directive (Default: http://localhost:80)
* BACKEND_WS - A string indicating the IP/URL of the WebSocket service (Default: ws://localhost:8080)
* ERRORLOG - A string value indicating the location of the error log file (Default: '/var/log/apache2/error.log')
* GROUP - A string value indicating the name (or #number) of the group to run httpd as (Default: daemon)
* HTTPD_MAX_REQUEST_WORKERS - AN integer indicating the maximum number of connections that will be processed simultaneously (Default: 250)
* LOGLEVEL - A string value controlling the number of messages logged to the error_log (Default: warn)
* METRICS_ALLOW_FROM - A string indicating a range of IP adresses that can access the apache metrics (Default: '127.0.0.0/255.0.0.0 ::1/128')
* METRICS_DENY_FROM -  A string indicating a range of IP adresses that cannot access the apache metrics (Default: All)
* METRICSLOG - A string indicating the path of the metrics log (Default: '/dev/null combined')
* PERFLOG - A string indicating the path of the performance log (Default: '/dev/stdout perflogjson env=write_perflog')
* PORT - An integer value indicating the port where the webserver is listening to (Default: 80)
* PROXY_PRESERVE_HOST - A string indicating the use of incoming Host HTTP request header for proxy request (Default: on)
* PROXY_SSL_CA_CERT_KEY - A string indicating the path to the server PEM-encoded private key file (Default: /usr/local/apache2/conf/server.key)
* PROXY_SSL_CA_CERT - A string indicating the path to the server PEM-encoded X.509 certificate data file or token identifier (Default: /usr/local/apache2/conf/server.crt)
* PROXY_SSL_CHECK_PEER_NAME - A string indicating if the host name checking for remote server certificates is to be enabled (Default: on)
* PROXY_SSL_VERIFY - A string value indicating the type of remote server Certificate verification (Default: none)
* PROXY_SSL - A string indicating SSL Proxy Engine Operation Switch (Default: off)
* PROXY_TIMEOUT - An intiger indicating the network timeout for proxied requests (Default: 42)
* REMOTEIP_INT_PROXY - A string indicating the client intranet IP addresses trusted to present the RemoteIPHeader value (Default: '10.1.0.0/16')
* SERVER_ADMIN - A string value indicating the address where problems with the server should be e-mailed (Default: root@localhost)
* REQ_HEADER_FORWARDED_PROTO - A string indicating the transfer protocol of the initial request (Default: 'https')
* SSL_ENGINE - A string indicating the SSL Engine Operation Switch (Default: off)
* TIMEOUT - ApAnache integer value indicating the number of seconds before receiving and sending time out (Default: 60)
* USER - A string value indicating the name (or #number) of the user to run httpd as (Default: daemon)

### Modsecurity ENV Variables

* MODSEC_AUDIT_LOG - A string indicating the path to the main audit log file or the concurrent logging index file (Default: /dev/stdout)
* MODSEC_AUDIT_LOG_FORMAT - A string indicating the output format of the AuditLogs (Default: JSON)
* MODSEC_AUDIT_LOG_TYPE - A string indicating the type of audit logging mechanism to be used (Default: Serial)
* MODSEC_AUDIT_STORAGE - A string indicating the directory where concurrent audit log entries are to be stored (Default: /var/log/modsecurity/audit/)
* MODSEC_DATA_DIR - A string indicating the path where persistent data (e.g., IP address data, session data, and so on) is to be stored (Default: /tmp/modsecurity/data)
* MODSEC_DEBUG_LOG - A string indicating the path to the ModSecurity debug log file (Default: /dev/null)
* MODSEC_DEBUG_LOGLEVEL - An integer indicating the verboseness of the debug log data (Default: 0)
* MODSEC_PCRE_MATCH_LIMIT - An integer value indicating the limit for the number of internal executions in the PCRE function (Default: 100000)
* MODSEC_PCRE_MATCH_LIMIT_RECURSION - An integer value indicating the limit for the depth of recursion when calling PCRE function (Default: 100000)
* MODSEC_REQ_BODY_ACCESS - A string value allowing ModSecurity to access request bodies (Default: on)
* MODSEC_REQ_BODY_LIMIT - An integer value indicating the maximum request body size  accepted for buffering (Default: 13107200)
* MODSEC_REQ_BODY_NOFILES_LIMIT - An integer indicating the maximum request body size ModSecurity will accept for buffering (Default: 131072)
* MODSEC_RESP_BODY_ACCESS - A string value allowing ModSecurity to access response bodies (Default: on)
* MODSEC_RESP_BODY_LIMIT - An integer value indicating the maximum response body size  accepted for buffering (Default: 1048576)
* MODSEC_RULE_ENGINE - A string value enabling ModSecurity itself (Default: on) 
* MODSEC_TAG - A string indicating the default tag action, which will be inherited by the rules in the same configuration context (Default: modsecurity)
* MODSEC_TMP_DIR - A string indicating the path where temporary files will be created (Default: /tmp/modsecurity/tmp)
* MODSEC_UPLOAD_DIR - A string indicating the path where intercepted files will be stored (Default: /tmp/modsecurity/upload)

## Image Variants

**Please pay attention!**
ModSecurity works across numerous different operating systems and webservers, as a result our images are tagged a bit different than what you might be typically encounter on other DockerHub repos. If the images are built on top of the images provided by the maintainers of the webserver (NGINX, Apache, etc), then they will be notated as simply as <version>-<webserver>. However, in many cases we understand that this is not sufficient for production deploys. As a result we also provide Ubuntu images. these will be in the form <version>-<webserver>-ubuntu.

* owasp/modsecurity:

   This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your rules and webapp then start the container to start your app), as well as the base to build other images off of. These will always be built on top of the images provided by the webserver developers on DockerHub. The owasp/modsecurity:latest will use 3.x which is will use the NGINX provided image (https://hub.docker.com/_/nginx) as a base.

* owasp/modsecurity:-nginx{-<x>}

   This image uses NGINX as its underlying webserver.

* owasp/modsecurity:-apache{-<x>}

   This image uses Apache as its underlying webserver.

* owasp/modsecurity:-<x>-ubuntu

   This image will use an ubuntu image provided by the Ubuntu DockerHub repo as its a base OS (https://hub.docker.com/_/ubuntu).

## License

License: Apache 2.0 license, see [LICENSE](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-apache/LICENSE).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Author: Chaim Sanders ([@csanders-git](https://github.com/csanders-git)) and contributors
