#!/bin/bash

set -m # for job control

port="${EMITIMES_PORT:-36000}"
user="${EMITIMES_USER:-user}"
password="${EMITIMES_PASSWORD:-password}"
calendar=${EMITIMES_CALENDAR:-emitimes}

envsub() {
  eval "cat <<EOF
$(cat "$1")
EOF
" 2>/dev/null
}

find ./conf -type f | while IFS= read -r file; do
  # shellcheck disable=SC2005
  echo "$(envsub "$file")" >"$file"
done

echo "$password" | htpasswd -i -c -m .htpasswd "$user"

TAKE_FILE_OWNERSHIP=false docker-entrypoint.sh radicale --config ./conf/config.cfg &

echo 'Setting up emitimes...'

base_url="http://localhost:$port"

while ! curl --fail "$base_url" >/dev/null 2>&1; do
  echo 'Waiting for emitimes to startup...'
  sleep 0.1
done

echo 'Connected to emitimes!'

calendar_url="$base_url/$user/$calendar"

echo 'Setting up calendar...'
if ! curl -s -f -u "$user:$password" "$calendar_url" >/dev/null 2>&1; then
  echo 'Creating calendar...'
  curl -s -u "$user:$password" -X MKCOL --data "@conf/calendar.xml" "$calendar_url"
else
  echo 'Calendar already exists! Skipping...'
fi

echo 'Emitimes setup finished!'

fg %1 >/dev/null
