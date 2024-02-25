#!/bin/bash

cp -v /auth/auth.tpz /opt/TopazVideoAIBETA/models/
echo IN_FILE: $IN_FILE
echo OUT_FILE: $OUT_FILE
echo FILTER: $FILTER
ffmpeg -y -i "/output/$IN_FILE" -pix_fmt yuv420p -flush_packets 1 -sws_flags spline+accurate_rnd+full_chroma_int -color_trc 2 -colorspace 2 -color_primaries 2 -filter_complex "$FILTER" -c:v h264_nvenc -profile:v high -preset medium -b:v 0 "/output/$OUT_FILE"