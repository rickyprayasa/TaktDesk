#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=4344

echo "=========================================================="
echo "  ZYKL // 1:1 SOCIAL MOTION GRAPHIC STUDIO (PORT $PORT)"
echo "=========================================================="
echo "Serving: $DIR"
echo "URL: http://127.0.0.1:$PORT/index.html"
echo ""

# Start python3 http.server in the background if not already running
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
  echo "Server already running on port $PORT."
else
  python3 -m http.server $PORT --directory "$DIR" &
  SERVER_PID=$!
  echo "Server started with PID $SERVER_PID."
fi

# Open in default browser
if which xdg-open > /dev/null; then
  xdg-open "http://127.0.0.1:$PORT/index.html"
elif which google-chrome > /dev/null; then
  google-chrome "http://127.0.0.1:$PORT/index.html"
fi

echo "Press Ctrl+C to exit or leave running."
wait
