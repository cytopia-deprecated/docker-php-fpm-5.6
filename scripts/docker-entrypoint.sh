#!/bin/sh -eu


run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}



################################################################################
# MAIN ENTRY POINT
################################################################################

##
## Adjust timezone
##
if set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		run "rm /etc/localtime"
		run "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
		run "date"

		# PHP Time
		run "sed -i'' 's|;*date.timezone[[:space:]]*=.*$|date.timezone = ${TIMEZONE}|g' /etc/php.ini"
	else
		echo >&2 "Invalid timezone for \$TIMEZONE."
		echo >&2 "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
else
	run "sed -i'' 's|;*date.timezone[[:space:]]*=.*$|date.timezone = UTC|g' /etc/php.ini"
fi



##
## Forward remote MySQL port to 127.0.0.1 ?
##
if set | grep '^FORWARD_MYSQL_PORT_TO_LOCALHOST=' >/dev/null 2>&1; then

	if [ "${FORWARD_MYSQL_PORT_TO_LOCALHOST}" = "1" ]; then
		if ! set | grep '^MYSQL_REMOTE_ADDR=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$MYSQL_REMOTE_ADDR must be set for this to work."
			exit 1
		fi
		if ! set | grep '^MYSQL_REMOTE_PORT=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$MYSQL_REMOTE_PORT must be set for this to work."
			exit 1
		fi
		if ! set | grep '^MYSQL_LOCAL_PORT=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$MYSQL_LOCAL_PORT must be set for this to work."
			exit 1
		fi

		##
		## Start socat tunnel
		## bring mysql to localhost
		##
		## This allos to connect via mysql -h 127.0.0.1
		##
		run "/usr/bin/socat tcp-listen:${MYSQL_LOCAL_PORT},reuseaddr,fork tcp:$MYSQL_REMOTE_ADDR:$MYSQL_REMOTE_PORT &"

	fi
fi



##
## Mount remote MySQL socket volume to local disk?
##
if set | grep '^MOUNT_MYSQL_SOCKET_TO_LOCALDISK=' >/dev/null 2>&1; then
	if [ "${MOUNT_MYSQL_SOCKET_TO_LOCALDISK}" = "1" ]; then
		if ! set | grep '^MYSQL_SOCKET_PATH=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to mount mysql socket to local disk."
			echo >&2 "\$MYSQL_SOCKET_PATH must be set for this to work."
			exit 1
		fi

		##
		## Tell MySQL Client where the socket can be found.
		##
		## This allos to connect via mysql -h localhost
		##
		run "echo '[client]'						> /etc/my.cnf"
		run "echo 'socket = ${MYSQL_SOCKET_PATH}'	>> /etc/my.cnf"

		run "echo '[mysql]'							>> /etc/my.cnf"
		run "echo 'socket = ${MYSQL_SOCKET_PATH}'	>> /etc/my.cnf"



		##
		## Tell PHP where the socket can be found.
		##
		## This allos to connect via mysql -h localhost
		##
		run "sed -i'' 's|mysql.default_socket.*$|mysql.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"
		run "sed -i'' 's|mysqli.default_socket.*$|mysqli.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"
		run "sed -i'' 's|pdo_mysql.default_socket.*$|pdo_mysql.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"

	fi
fi



##
## Start
##
run "hostname -I"
run "php-fpm -v 2>&1 | head -1"
run "/usr/sbin/php-fpm -F"
