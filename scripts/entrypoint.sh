#!/bin/bash

# Activate runtime shell
# shellcheck source=/dev/null
. /env/activate

# Set permissions
chown -R app:app /app

# Run as non-root user
# Use tini to handle signals
su-exec app tini -s -- "$@"
