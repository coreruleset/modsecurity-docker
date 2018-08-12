#!/bin/sh

if [ ! -z $PROXY ]; then
  if [ $PROXY -eq 1 ]; then
    APACHE_ARGUMENTS='-D modsec_proxy'
    if [ -z "$UPSTREAM" ]; then
      export UPSTREAM=$(/sbin/ip route | grep ^default | perl -pe 's/^.*?via ([\d.]+).*/$1/g'):81
    fi
  fi
fi

exec "$@" $APACHE_ARGUMENTS
