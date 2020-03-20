#!/bin/sh
#
# Expects a semver "LABEL version" in a Dockerfile,
# parses it into <major>.<minor>.<patch>
#
TARGET="${1%%/}"
TYPE="$2"

[ -z "$TARGET" ] && {
    echo "Usage: $0 <directory> [-v|-vv|-vvv|-vvvv]"
    exit 1
}

version=$(grep "LABEL version" "$TARGET/Dockerfile" | sed -e 's/^.*="//' -e 's/"$//')
major="${version%%.*}"
patch="${version##*.}"
nomaj="${version#$major.}"
minor="${nomaj%.$patch}"
humanized="${TARGET#*-}"

case "$TYPE" in
    -v)
        echo "${major}"
        ;;
    -vv)
        echo "${major}.${minor}"
        ;;
    -vvv)
        echo "${major}.${minor}.${patch}"
        ;;
    *)
        echo "${humanized}"
esac
