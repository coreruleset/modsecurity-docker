#!/bin/sh
#
# Expects a semver "MODSEC_VERSION=version" in a Dockerfile,
# parses it into <major>.<minor>.<patch>
#
TARGET="${1%%/}"
TYPE="$2"
# Variant allows us to generate variants like '-alpine'
VARIANT="$3"

[ -z "$TARGET" ] && {
    echo "Usage: $0 <directory> [-v|-vv|-vvv|-vvvv]"
    exit 1
}

version=$(grep -m1 "ARG MODSEC_VERSION" "$TARGET/Dockerfile${VARIANT}" | cut -f2 -d=)
major="${version%%.*}"
patch="${version##*.}"
nomaj="${version#$major.}"
minor="${nomaj%.$patch}"
humanized="${TARGET#*-}"
variant="${VARIANT}"

case "$TYPE" in
    -v)
        echo "${major}${variant}"
        ;;
    -vv)
        echo "${major}.${minor}${variant}"
        ;;
    -vvv)
        echo "${major}.${minor}.${patch}${variant}"
        ;;
    *)
        echo "${humanized}${variant}"
esac
