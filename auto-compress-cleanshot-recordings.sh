#!/bin/bash
#
# Auto-Compress CleanShot Recordings
# Watches ~/Downloads for new video files and compresses them
# using HandBrake "Fast 1080p30" equivalent settings.
# Deletes the original 5 minutes after compression.
#
# Usage: ./auto-compress-cleanshot.sh
# Requirements: brew install ffmpeg fswatch

WATCH_DIR="$HOME/Downloads"

FFMPEG="/opt/homebrew/bin/ffmpeg"
FSWATCH="/opt/homebrew/bin/fswatch"
BC="/usr/bin/bc"

compress_video() {
    local file="$1"
    local dir
    local filename
    local name
    local output

    dir=$(dirname "$file")
    filename=$(basename "$file")
    name="${filename%.*}"
    output="$dir/${name} Auto-Compressed.mp4"

    # Skip if already compressed or output exists
    [[ "$name" == *"Auto-Compressed"* ]] && return
    [[ -f "$output" ]] && return

    # Wait for file to be fully written
    local prev_size=0
    local curr_size=1
    while [[ "$prev_size" != "$curr_size" ]]; do
        prev_size=$(stat -f%z "$file" 2>/dev/null || echo 0)
        sleep 2
        curr_size=$(stat -f%z "$file" 2>/dev/null || echo 0)
    done

    # Compress
    "$FFMPEG" -i "$file" \
        -c:v libx264 -preset fast -crf 22 \
        -vf "scale=-2:'min(1080,ih)'" -r 30 \
        -c:a aac -b:a 160k \
        -movflags +faststart \
        -y -loglevel warning \
        "$output" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        local out_mb
        out_mb=$(echo "scale=1; $(stat -f%z "$output") / 1048576" | "$BC")
        local ratio
        ratio=$(echo "scale=0; 100 - ($(stat -f%z "$output") * 100 / $curr_size)" | "$BC")

        osascript -e "display notification \"${filename} → ${out_mb}MB (${ratio}% smaller)\" with title \"Auto-Compress\" sound name \"Glass\""

        # Delete original after 5 minutes if it still exists with the same name
        (sleep 300 && [[ -f "$file" ]] && rm "$file") &
    else
        rm -f "$output"
        osascript -e "display notification \"Failed to compress ${filename}\" with title \"Auto-Compress\" sound name \"Basso\""
    fi
}

# Check dependencies
for cmd in "$FFMPEG" "$FSWATCH" "$BC"; do
    if [[ ! -x "$cmd" ]]; then
        echo "Error: $cmd not found"
        exit 1
    fi
done

# Watch for new video files
"$FSWATCH" -0 \
    --event Created \
    --event MovedTo \
    -e ".*" \
    -i "\\.mov$" -i "\\.mp4$" -i "\\.m4v$" \
    "$WATCH_DIR" | while read -d "" file; do

    [[ "$(dirname "$file")" != "$WATCH_DIR" ]] && continue
    [[ "$(basename "$file")" != CleanShot* ]] && continue
    [[ "$file" == *"Auto-Compressed"* ]] && continue

    compress_video "$file" &
done
