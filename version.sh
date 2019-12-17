#!/bin/sh
#
# Expects a semver "LABEL version" in a Dockerfile,
# parses it into <major>.<minor>.<patch>
#
TARGET="$1"
TYPE="$2"

[ -z "$TARGET" ] && {
    echo "Usage: $0 <directory> [-v|-vv|-vvv]"
    exit 1
}

version=$(grep "LABEL version" "$TARGET/Dockerfile" | sed -e 's/^.*="//' -e 's/"$//')
major="${version%%.*}"
patch="${version##*.}"
nomaj="${version#$major.}"
minor="${nomaj%.$patch}"

case "$TYPE" in
    -v)
        echo "${major}"
        ;;
    -vv)
        echo "${major}.${minor}"
        ;;
    *)
        echo "${major}.${minor}.${patch}"
esac
