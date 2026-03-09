#!/bin/sh
set -e
# Start Discord bot in background; Link app must be PID 1 so Railway gets health/signals
/usr/local/bin/spoticord &
exec node server.js
