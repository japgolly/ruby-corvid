#!/bin/sh

cd "$(dirname "$0")" || exit
dir="$(pwd)"
rm -f *.patch
cd ../../..
dir="$dir" bundle exec rake res:fixture
