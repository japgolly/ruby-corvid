#!/bin/bash

i=0
for rev in `cat ver_log.log | perl -pe 's/^.*?([0-9a-f]{7}).*$/\1/g' | xargs`; do
  echo $rev $i

  (cd /tmp/1 \
    && git co -q $rev \
    && cp -R templates ~/projects/corvid/resources/l-$i
  ) || exit 2

  i=$((i+1))
done

echo "Done!"
