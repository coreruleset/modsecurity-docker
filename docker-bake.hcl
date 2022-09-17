# docker-bake.hcl
variable "apache_modsec_version" {
    default = "2.9.6"
}

variable "nginx_modsec_version" {
    default = "3.0.8"
}

variable "REPO" {
  default = "owasp/modsecurity"
}

function "major" {
    params = [version]
    result = split(".", version)[0]
}

function "minor" {
    params = [version]
    result = join(".", slice(split(".", version),0,2))
}

function "patch" {
    params = [version]
    result = join(".", slice(split(".", version),0,3))
}

function "tag" {
    params = [tag]
    result = ["${REPO}:${tag}"]
}

function "vtag" {
    params = [semver, variant]
    result = concat(
        tag("${major(semver)}${variant}-${formatdate("YYYYMMDDHHMM", timestamp())}"),
        tag("${minor(semver)}${variant}-${formatdate("YYYYMMDDHHMM", timestamp())}"),
        tag("${patch(semver)}${variant}-${formatdate("YYYYMMDDHHMM", timestamp())}")
    )
}

group "default" {
    targets = [
        "apache",
        "apache-alpine",
        "nginx",
        "nginx-alpine"
    ]
}

target "docker-metadata-action" {}

target "build" {
  inherits = ["docker-metadata-action"]
  context = "./"
  platforms = [
    "linux/amd64", 
    "linux/arm64/v8", 
    "linux/arm/v7", 
    "linux/i386"
  ]
}

target "apache" {
    inherits = ["build"]
    dockerfile="v2-apache/Dockerfile"
    tags = concat(tag("apache"),
        vtag("${apache_modsec_version}", "")
    )
    args = {
        MODSEC_VERSION = "${apache_modsec_version}"
    }
}

target "apache-alpine" {
    inherits = ["build"]
    dockerfile="v2-apache/Dockerfile-alpine"
    tags = concat(tag("apache-alpine"),
        vtag("${apache_modsec_version}", "-alpine")
    )
    args = {
        MODSEC_VERSION = "${apache_modsec_version}"
    }
}

target "nginx" {
    inherits = ["build"]  
    dockerfile="v3-nginx/Dockerfile"
    tags = concat(tag("nginx"),
        vtag("${nginx_modsec_version}", "")
    )
    args = {
        MODSEC_VERSION = "${nginx_modsec_version}"
    }
}

target "nginx-alpine" {
    inherits = ["build"]
    dockerfile="v3-nginx/Dockerfile-alpine"
    tags = concat(tag("nginx-alpine"),
        vtag("${nginx_modsec_version}", "-alpine")
    )
    args = {
        MODSEC_VERSION = "${nginx_modsec_version}"
    }
}
