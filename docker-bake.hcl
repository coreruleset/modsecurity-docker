# docker-bake.hcl
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
    tags = ["apache:2"]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}

target "apache-alpine" {
    context="."    
    dockerfile="v2-apache/Dockerfile-alpine"
    tags = ["apache:2-alpine"]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}

target "nginx" {
    context="."    
    dockerfile="v3-nginx/Dockerfile"
    tags = ["nginx:3"]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}

target "nginx-alpine" {
    context="."    
    dockerfile="v3-nginx/Dockerfile-alpine"
    tags = ["nginx:3-alpine"]
    platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}