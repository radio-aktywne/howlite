#!/bin/sh

### Constants

datadir=data/

### Temporary files

tmpconfig="$(mktemp --suffix=.yaml)"
tmpradicaleconfig="$(mktemp --suffix=.cfg)"

### Functions

# Cleanup function to remove temporary files
cleanup() {
	rm --force "${tmpconfig}" "${tmpradicaleconfig}"
}

# Function to fill values in the configuration file
fillconfig() {
	gomplate --file src/config.yaml.tpl --out "${1}"
}

# Function to fill values in the Radicale configuration file
fillradicaleconfig() {
	gomplate --file src/radicale.cfg.tpl --datasource config="${1}" --out "${2}"
}

# Function to setup ignoring signals
ignoresignals() {
	for signal in INT TERM HUP QUIT; do
		trap '' "${signal}"
	done
}

# Function to make preparations before starting Radicale
prepare() {
	password="$(yq eval '.credentials.password' "${1}")"
	user="$(yq eval '.credentials.user' "${1}")"

	# Ensure data directory exists
	mkdir --parents "${datadir}"

	# Create htpasswd file
	echo "${password}" | htpasswd -ic "${datadir}/.htpasswd" "${user}"
}

# Function to start Radicale
startradicale() {
	echo 'Starting Radicale...'

	radicale --config "${1}" &
}

# Function to setup signal handling
handlesignals() {
	for signal in INT TERM HUP QUIT; do
		trap 'kill -'"${signal}"' '"${1}"'; wait '"${1}"'; status=$?; cleanup; exit "${status}"' "${signal}"
	done
}

# Function to wait until Radicale is ready
waituntilready() {
	retries=30
	interval=1
	url="http://localhost:$(yq eval '.server.port' "${1}")"

	for i in $(seq 1 "${retries}"); do
		if [ "${i}" -eq "${retries}" ]; then
			echo 'Could not connect to Radicale!'
			exit 1
		fi

		if curl --silent --head --fail "${url}" >/dev/null; then
			echo 'Connected to Radicale!'
			break
		else
			echo 'Waiting for connection to Radicale...'
			sleep "${interval}"
		fi
	done
}

# Function to setup Radicale
setup() {
	calendar="$(yq eval '.calendar' "${1}")"
	password="$(yq eval '.credentials.password' "${1}")"
	user="$(yq eval '.credentials.user' "${1}")"
	url="http://localhost:$(yq eval '.server.port' "${1}")"

	echo 'Running setup...'

	# Create calendar if it doesn't exist
	if ! PASSWORD="${password}" curl --variable '%PASSWORD' --silent --fail --head --expand-user "${user}:{{PASSWORD}}" "${url}/${user}/${calendar}" >/dev/null; then
		echo 'Creating calendar...'
		PASSWORD="${password}" curl --variable '%PASSWORD' --silent --request MKCALENDAR --expand-user "${user}:{{PASSWORD}}" "${url}/${user}/${calendar}" >/dev/null
	fi

	# Update calendar metadata
	echo 'Updating calendar metadata...'
	PASSWORD="${password}" curl --variable '%PASSWORD' --silent --request PROPPATCH --expand-user "${user}:{{PASSWORD}}" --data '@src/calendar.xml' "${url}/${user}/${calendar}" >/dev/null
}

# Function to wait for Radicale to exit and handle cleanup
waitandcleanup() {
	wait "${1}"
	status=$?

	# Cleanup temporary files
	cleanup

	exit "${status}"
}

### Main script execution

# Fill values in configuration files
fillconfig "${tmpconfig}"
fillradicaleconfig "${tmpconfig}" "${tmpradicaleconfig}"

# Make preparations
prepare "${tmpconfig}"

# Temporarily ignore signals
ignoresignals

# Start Radicale in the background
startradicale "${tmpradicaleconfig}"

# Setup signal handling
pid=$!
handlesignals "${pid}"

# Wait for Radicale to start
waituntilready "${tmpconfig}"

# Run setup
setup "${tmpconfig}"

echo 'Radicale is ready!'

# Wait for Radicale to exit
waitandcleanup "${pid}"
