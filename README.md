# ModSecurity Docker Image

[hub]: https://hub.docker.com/r/owasp/modsecurity

## What is ModSecurity

ModSecurity is an open source,
cross platform
web application firewall (WAF) engine
for Apache, IIS and Nginx

## How to use this image

Build the image:

```
docker build -t modsec .
```

Run the Image:

```
docker run -ti --rm -p 80:80 modsec
```

This will start an Apache Webserver,
on port 80,
with ModSecurity installed.

You can access this webserver typically by
navigating to [http://localhost](http://localhost)

*Note:* ModSecurity without any ruleset isn't very helpful.
A common ruleset,
the OWASP Core Rule Set (CRS),
is available free on [GitHub](https://github.com/SpiderLabs/owasp-modsecurity-crs/).
CRS has it's own Dockerfile that builds on this image.

### Settings

This image builds ModSecurity
with the recommended configuration by default.

This configuration blocks very little.
Please see the [Recommended Configuration](https://github.com/SpiderLabs/ModSecurity/blob/v2/master/modsecurity.conf-recommended)
for more details

## Configuration

At this point,
there are no configuration options
for this image.

## License

License: Apache 2.0 license, see [LICENSE](LICENSE).
Author: Chaim Sanders ( @csanders-git ) and contributors
