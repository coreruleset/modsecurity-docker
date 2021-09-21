# docker-bake.hcl
variable "apache_modsec_version" {
    default = "2.9.4"
}

variable "nginx_modsec_version" {
    default = "3.0.5"
}

function "major" {
    params = [version]
    result = split(".", version)[0]
}

function "minor" {
    params = [version]
    result = join(".", slice(split(".", version),0,2))
}
# result = split(version, ".")[0] + "." + split(version, ".")[1] "." + split(version, ".")[2]
function "patch" {
    params = [version]
    result = join(".", slice(split(".", version),0,3))
}

group "default" {
    targets = [
        "apache",
        "apache-alpine",
        "nginx",
        "nginx-alpine"
    ]
}

target "apache" {
    context="."
    dockerfile="v2-apache/Dockerfile"
    tags = [
        "owasp/modsecurity:apache",
        "owasp/modsecurity:${major(apache_modsec_version)}",
        "owasp/modsecurity:${minor(apache_modsec_version)}",
        "owasp/modsecurity:${patch(apache_modsec_version)}"
    ]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7", "linux/i386"]
    args = {
        MODSEC_VERSION = "${apache_modsec_version}"
    }
}

target "apache-alpine" {
    context="."    
    dockerfile="v2-apache/Dockerfile-alpine"
    tags = [
        "owasp/modsecurity:apache-alpine",
        "owasp/modsecurity:${major(apache_modsec_version)}-alpine",
        "owasp/modsecurity:${minor(apache_modsec_version)}-alpine",
        "owasp/modsecurity:${patch(apache_modsec_version)}-alpine"
    ]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7", "linux/i386"]
    args = {
        MODSEC_VERSION = "${apache_modsec_version}"
    }
}

target "nginx" {
    context="."    
    dockerfile="v3-nginx/Dockerfile"
    tags = [
        "owasp/modsecurity:nginx",
        "owasp/modsecurity:${major(nginx_modsec_version)}",
        "owasp/modsecurity:${minor(nginx_modsec_version)}",
        "owasp/modsecurity:${patch(nginx_modsec_version)}"
    ]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7", "linux/i386"]
    args = {
        MODSEC_VERSION = "${nginx_modsec_version}"
    }
}

target "nginx-alpine" {
    context="."    
    dockerfile="v3-nginx/Dockerfile-alpine"
    tags = [
        "owasp/modsecurity:nginx-alpine",
        "owasp/modsecurity:${major(nginx_modsec_version)}-alpine",
        "owasp/modsecurity:${minor(nginx_modsec_version)}-alpine",
        "owasp/modsecurity:${patch(nginx_modsec_version)}-alpine"
    ]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7", "linux/i386"]
    args = {
        MODSEC_VERSION = "${nginx_modsec_version}"
    }
}
