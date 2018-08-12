# ModSecurity Docker Image

[hub]: https://hub.docker.com/r/owasp/modsecurity

## What is ModSecurity

ModSecurity is an open source,
cross platform
web application firewall (WAF) engine
for Apache, IIS and Nginx

## How to use this image

### 1. Build the image:

```
docker build -t modsec .
```

*Note:* ModSecurity without any ruleset isn't very helpful.
A common ruleset,
the OWASP Core Rule Set (CRS),
is available free on [GitHub](https://github.com/SpiderLabs/owasp-modsecurity-crs/).
CRS has it's own Dockerfile that builds on this image.

### 2a. Run the Image (example 1):

```
docker run -ti --rm -p 80:80 modsec
```

This will start an Apache Webserver,
on port 80,
with ModSecurity installed.

You can access this webserver typically by
navigating to [http://localhost](http://localhost)

### 2b. Run the Image (example 2):

```
docker run -ti --rm -p 80:80 -e PROXY=1 modsec
```

This will start an Apache webserver on
port 80 that proxies traffic from port
81 on the Docker host.

## Default WAF Settings

This image builds ModSecurity
with the recommended configuration by default.

This configuration blocks very little.
Please see the [Recommended Configuration](https://github.com/SpiderLabs/ModSecurity/blob/v2/master/modsecurity.conf-recommended)
for more details.

## Configuration

All configuration is currently don via
environment variables. The following
environment variables are available to
configure the CRS container:

| Name     | Description|
| -------- | ------------------------------------------------------------------- |
| PROXY    | An integer indicating if reverse proxy mode is enabled (Default: 0) |
| UPSTREAM | The IP Address (and optional port) of the upstream server when proxy mode is enabled. (Default: the container's default router, port 81) (Examples: 192.0.2.2 or 192.0.2.2:80) |

## Notes regarding reverse proxy

In order to more easily test drive the mod_security WAF, we include support for an technique called [Reverse Proxy](https://en.wikipedia.org/wiki/Reverse_proxy). Using this technique, you keep your pre-existing web server online at a non-standard host and port, and then configure the mod_security container to accept public traffic. The mod_security container then proxies the traffic to your pre-existing webserver. This way, you can test out mod_security with any web server. Some notes:

* Proxy is not enabled by default. You'll need to pass the `-e PROXY=1` environment variable to enable it.
* You'll want to configure your typical webserver to listen on your docker interface only (i.e. 172.17.0.1:81) so that public traffic doesn't reach it.
* Do not use 127.0.0.1 as an UPSTREAM address. The loopback interface inside the docker container is not the same interface as the one on docker host.
* Note that traffic coming through this proxy will look like it's coming from the wrong address. You may want to configure your pre-existing webserver to use the `X-Forwarded-For` HTTP header to populate the remote address field for traffic from the proxy.

## License

License: Apache 2.0 license, see [LICENSE](LICENSE).
Author: Chaim Sanders ( @csanders-git ) and contributors
