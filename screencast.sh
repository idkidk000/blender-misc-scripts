#!/bin/bash
pgrep screenkey > /dev/null
if [ $? -ne 0 ]; then
    screenkey --show-settings
    read -p "Press enter to begin" dummy
fi
ffmpeg -video_size 1920x1020 -f x11grab -framerate 24 -i :0.0+1,1100 -c:v h264_nvenc -qp 0 -t 30 -y /tmp/capture.mkv
