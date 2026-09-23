#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=4344

echo "=========================================================="
echo "  ZYKL // 1:1 CINEMATIC MOTION GRAPHIC STUDIO (PORT $PORT)"
echo "=========================================================="
echo "Serving: $DIR"
echo "URL: http://127.0.0.1:$PORT/index.html"
echo ""

# Start server.mjs in the background if not already listening
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
  echo "Server already running on port $PORT."
else
  node "$DIR/server.mjs" &
  SERVER_PID=$!
  echo "Node.js streaming server started with PID $SERVER_PID."
  sleep 1
fi

# Open in default browser (google-chrome or xdg-open)
if command -v google-chrome &> /dev/null; then
  google-chrome "http://127.0.0.1:$PORT/index.html" &
elif command -v chromium-browser &> /dev/null; then
  chromium-browser "http://127.0.0.1:$PORT/index.html" &
elif command -v xdg-open &> /dev/null; then
  xdg-open "http://127.0.0.1:$PORT/index.html" &
fi

echo "Studio is active! Press Ctrl+C to stop server."
wait
