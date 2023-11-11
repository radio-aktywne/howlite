#!/bin/sh

# Configuration
port="${EMITIMES_PORT:-36000}"
user="${EMITIMES_USER:-user}"
password="${EMITIMES_PASSWORD:-password}"
calendar=${EMITIMES_CALENDAR:-emitimes}

baseurl="http://localhost:${port}"
calendarurl="${baseurl}/${user}/${calendar}"

retries=30
interval=1

datadir=data

tmpdir=$(mktemp --directory --tmpdir=/tmp)
tmpcalendar="${tmpdir}/calendar.xml"
tmpconfig="${tmpdir}/config.cfg"

# Make sure the data directory exists
mkdir --parents "${datadir}"

# Replace environment variables in config files and save to temporary directory
envsubst <src/cfg/calendar.xml >"${tmpcalendar}"
envsubst <src/cfg/config.cfg >"${tmpconfig}"

# Create htpasswd file
echo "${password}" | htpasswd -ic "${datadir}/.htpasswd" "${user}"

# Start Radicale with the provided config in the background
radicale --config "${tmpconfig}" &

echo 'Setting up...'

# Wait for Radicale to start up using curl
for i in $(seq 1 "${retries}"); do
	if [ "${i}" -eq "${retries}" ]; then
		echo 'Could not connect to Radicale!'
		exit 1
	fi

	if curl --silent --head --fail "${baseurl}" >/dev/null; then
		echo 'Connected to Radicale!'
		break
	else
		echo 'Waiting for connection to Radicale...'
		sleep "${interval}"
	fi
done

# Create calendar if it doesn't exist
if ! curl --silent --fail --head --user "${user}:${password}" "${calendarurl}" >/dev/null; then
	echo 'Creating calendar...'
	curl --silent --request MKCALENDAR --user "${user}:${password}" "${calendarurl}" >/dev/null
fi

# Update calendar metadata
echo 'Updating calendar metadata...'
curl --silent --request PROPPATCH --user "${user}:${password}" --data "@${tmpcalendar}" "${calendarurl}" >/dev/null

echo 'Setup complete!'

# Wait for Radicale to exit
wait

# Cleanup
rm -rf "${tmpdir}"
