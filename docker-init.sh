#!/bin/bash
login_help() {
  sleep 1 
  LISTEN=$(netstat -antp 2>/dev/null |grep login|awk '{print $4}')
  echo ""
  echo "1. Make sure to setup a SSH tunnel first, from a machine with a browser to the docker host machine." 
  echo "ssh -L $LISTEN:$LISTEN $HOSTNAME"
  echo
  echo "2. Then paste the URL above into the browser (i.e. LOGIN|<url>|)"
  echo
  echo "The auth.tpz (license) will be in a subdirectory ./auth/ on the host."
  echo "Make sure this file is mounted (or copied) to /opt/TopazVideoAIBETA/models in the container at runtime."
  echo
}

login() {
  login_help&
  /opt/TopazVideoAIBETA/bin/login
  auth_file="${TVAI_MODEL_DIR}/auth.tpz"
  [ -f "${auth_file}" ] || {
    echo "Authentication failed: auth.tpz not minted by the login program"
    exit 1
  }
  cp "${auth_file}" /auth/
  echo "Success: auth file now present on the host in ./auth/"
}

process() {
  cp /auth/auth.tpz /opt/TopazVideoAIBETA/models/auth.tpz
  echo IN_FILE: $IN_FILE
  echo OUT_FILE: $OUT_FILE
  echo FILTER: $FILTER
  ffmpeg -y -i "/output/$IN_FILE" -pix_fmt yuv420p -flush_packets 1 -sws_flags spline+accurate_rnd+full_chroma_int -color_trc 2 -colorspace 2 -color_primaries 2 -filter_complex "$FILTER" -c:v h264_nvenc -profile:v high -preset medium -b:v 0 "/output/$OUTFILE"
}

case $1 in
  login) login ;;
  process) process ;;
  *) exec "$@" ;;
esac

