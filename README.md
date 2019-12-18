# Supported tags and respective `Dockerfile` links
* `3.0.3-nginx`,  `3.0-nginx`,`3-nginx`, `latest` ([3.0/nginx/nginx/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v3/nginx-nginx/Dockerfile))
* `3.0.3-apache`, `3.0-apache`, `3-apache` ([3.0/apache/httpd/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v3/apache-apache/Dockerfile))
* `2.9.3-apache`,`2.9-apache`, `2-apache` ([2.9/apache/httpd/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/apache-apache/Dockerfile))
* `2.9.3-nginx`, `2.9-nginx`, `2-nginx` (2.9/nginx/nginx/Dockerfile)
* `2.9-apache-ubuntu` ([2.9/apache/ubuntu/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-apache/Dockerfile))
* `2.9-nginx-ubuntu` ([2.9/nginx/ubuntu/Dockerfile](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-nginx/Dockerfile))

# Quick reference
* **Where to get help**

   [The CRS-Support Docker Repo](https://github.com/CRS-support/modsecurity-docker), [The Core Rule Set Slack Channel](https://join.slack.com/t/owasp/shared_invite/enQtNjExMTc3MTg0MzU4LTViMDg1MmJiMzMwZGUxZjgxZWQ1MTE0NTBlOTBhNjhhZDIzZTZiNmEwOTJlYjdkMzAxMGVhNDkwNDNiNjZiOWQ) (#coreruleset on owasp.slack.com), or [Stack Overflow](https://stackoverflow.com/questions/tagged/mod-security)

* **Where to file issues**

    [The CRS-Support Docker Repo](https://github.com/CRS-support/modsecurity-docker)

* **Maintained By**

   The OWASP Core Rule Set maintainers

# What is ModSecurity
ModSecurity is an open source, cross platform Web Application Firewall (WAF) engine for Apache, IIS and Nginx. It has a robust event-based programming language which provides protection from a range of attacks against web applications and allows for HTTP traffic monitoring, logging and real-time analysis.

# How to use this image
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

## TLS/HTTPS
If you want to run your web traffic over TLS you can simply set the SETTLS argument to true when using Docker build. Note: This will use self signed certificates, to use your own certificates (recommended) COPY or mount (-v) your server.crt and server.key into /usr/local/apache2/conf/. Please remember you'll need to forward the HTTPS port

```
$docker build  --build-arg SETTLS=True -t my-modsec .
$docker run -p 8443:443 my-modsec
```

## Proxying
ModSecurity is often used as a reverse proxy. This allows one to use ModSecurity without modifying the webserver hosting the underlying application (and also protect web servers that modsecurity cannot currently embedd into). To set proxying one must set SETPROXY to True and provide the location of the Proxy via the PROXYLOCATION argument. Note: if you are going to be proxying to a HTTPS site, you'll need to set SETTLS to true also.

```
$docker build --build-arg SETPROXY=True --build-arg PROXYLOCATION=http://example.com -t my-modsec .
$ docker run -p 8080:80 my-modsec
```

## ServerName
It is often convenient to set your servername. to do this simply use the SERVERNAME Argument passed to docker build. By default the servername provided is localhost.
```
$ docker build --build-arg SERVERNAME=myhost -t modsec .
$ docker run -p 8080:80 my-modsec
```

# Image Variants
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

# License


License: Apache 2.0 license, see [LICENSE](https://github.com/CRS-support/modsecurity-docker/blob/v2/ubuntu-apache/LICENSE).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Author: Chaim Sanders ([@csanders-git](https://github.com/csanders-git)) and contributors
