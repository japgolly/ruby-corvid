#/bin/bash

if [ $# -ne 1 -o "$1" == "-h" -o "$1" == "--help" ]; then
  echo "Generates a plugin project and a client that uses it."
  echo
  echo "Usage: $(basename $0) <dir>"
  exit 1
fi

function noisily {
  echo "> $*"
  "$@" && echo
}

function patch_gemfile {
  sed -i -e "
    s!\(corvid.*\)\$!\1, path: '$corvid_home'!
    /golly-utils/d; \$i$golly_utils_dep
  " .corvid/Gemfile
}

corvid_home="$(dirname $0)/../.."
corvid_home="$(cd "$corvid_home" && pwd)"
corvid="$corvid_home/bin/corvid"
[ ! -f "$corvid" ] && echo "Corvid bin not found: $corvid" && exit 1

golly_utils_dep="$(fgrep golly-utils "$corvid_home/Gemfile")"

p=plugin_project
c=client_project

( [ -e "$1" ] || mkdir -p "$1" ) && cd "$1" \
  && mkdir "$p" && cd "$p" \
  && noisily "$corvid" init --no-test-unit --no-test-spec --no-run-bundle \
  && noisily patch_gemfile \
  && noisily "$corvid" init:plugin \
  && noisily "$corvid" new:plugin p1 \
  && noisily "$corvid" new:feature f1 \
  && cd .. \
  && mkdir "$c" && cd "$c" \
  && noisily "$corvid" init --no-test-unit --no-test-spec --no-run-bundle \
  && noisily patch_gemfile \
  && noisily ../"$p"/bin/p1 install --no-run-bundle \
  && noisily sed -i -e "s!\($p.*\)\$!\1, path: '../$p'!" Gemfile \
  && bundle install --local
