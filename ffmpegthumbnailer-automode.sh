#!/bin/bash
find "$1" -type f -not -path "*/.*" \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" \) -exec ffmpegthumbnailer -i {} -o ~/.cache/thumbnails/normal/$(echo -n "file://{}" | md5sum | cut -d' ' -f1).png -s 128 \;
