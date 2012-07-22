#!/bin/bash

rm -rf resources/*.patch resources/latest

i=17
while [[ $i -ne -1 ]]; do
  echo $i

  cp -Rp resources/l-$i/. resources/latest
  bundle exec rake res:new

  i=$((i-1))
done
