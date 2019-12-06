#!/bin/bash
set -e

REMOTE_BRANCHES=$(git branch --remote | grep "^  origin/v." | sed "s|^  origin/||" | xargs)

for BRANCH in $REMOTE_BRANCHES; do
    NAME=modsecurity-docker_${BRANCH/\//-}
    RESULT=`echo ${BRANCH/\//-} | sed -E 's/(.*)-(.*)-(.*)/\1-\3-\2/'`
    echo "Checkout branch $BRANCH as $NAME ..."
    git clone --quiet -b $BRANCH git@github.com:CRS-support/modsecurity-docker.git $NAME
    rm -fv $NAME/LICENSE
    rm -fv $NAME/README*
    rm -fv $NAME/CONTRIBUTORS*
    rm -rf $NAME/.git
    mv -iv $NAME $RESULT
done

echo "Rename folders we want to keep ..."
mv -iv v2-apache{-apache,}
mv -iv v2-nginx{-ubuntu,}
mv -iv v3-apache{-apache,}
mv -iv v3-nginx{-nginx,}

echo "Remove other, unused branch-based folders ..."
rm -rv v{2,3}-*-*/
