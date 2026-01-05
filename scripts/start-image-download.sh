#!/bin/bash

# POI Image Download Runner
# This script starts the image downloader in the background
#
# Usage:
#   ./scripts/start-image-download.sh [country-code ...]
#
# Examples:
#   ./scripts/start-image-download.sh          # All countries
#   ./scripts/start-image-download.sh us it fr # Specific countries
#
# To set Unsplash API key (recommended for better rate limits):
#   export UNSPLASH_ACCESS_KEY="your-key-here"
#   ./scripts/start-image-download.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/poi-images-download.log"
PID_FILE="$PROJECT_DIR/.poi-download.pid"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Download already running (PID: $OLD_PID)"
        echo "To stop: kill $OLD_PID"
        echo "To monitor: tail -f $LOG_FILE"
        exit 1
    fi
fi

# Start the download
echo "Starting POI image download..."
echo "Log file: $LOG_FILE"

cd "$PROJECT_DIR"
nohup node scripts/download-poi-images-unsplash.js "$@" >> "$LOG_FILE" 2>&1 &
NEW_PID=$!
echo $NEW_PID > "$PID_FILE"

echo "Started (PID: $NEW_PID)"
echo ""
echo "Commands:"
echo "  Monitor:  tail -f $LOG_FILE"
echo "  Status:   ps -p $NEW_PID"
echo "  Stop:     kill $NEW_PID"
echo "  Count:    find data/pois/images -name '*.webp' | wc -l"
