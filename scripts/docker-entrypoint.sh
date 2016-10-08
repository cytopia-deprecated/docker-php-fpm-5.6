#!/bin/sh -eu

##
## Variables
##
PHP_FPM_POOL_CONF="/etc/php-fpm.d/www.conf"
PHP_FPM_DEFAULT_PORT="9000"
PHP_XDEBUG_DEFAULT_PORT="9000"


##
## Functions
##
run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}
# Test if argument is an integer.
#
# @param  mixed
# @return integer	0: is number | 1: not a number
isint(){
	printf "%d" "${1}" >/dev/null 2>&1 && return 0 || return 1;
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
## PHP-FPM Listening Port
##
if ! set | grep '^PHP_FPM_PORT=' >/dev/null 2>&1; then
	echo >&2 "\$PHP_FPM_PORT not set, defaulting to ${PHP_FPM_DEFAULT_PORT}"
	PHP_FPM_PORT="${PHP_FPM_DEFAULT_PORT}"
elif ! isint "${PHP_FPM_PORT}"; then
	echo >&2 "\$PHP_FPM_PORT is not a valid integer: ${PHP_FPM_PORT}"
	echo >&2 "\Defaulting to ${PHP_FPM_DEFAULT_PORT}"
	PHP_FPM_PORT="${PHP_FPM_DEFAULT_PORT}"
elif [ "${PHP_FPM_PORT}" -lt "1" ] || [ "${PHP_FPM_PORT}" -gt "65535" ]; then
	echo >&2 "\$PHP_FPM_PORT is out of range: ${PHP_FPM_PORT}"
	echo >&2 "\Defaulting to ${PHP_FPM_DEFAULT_PORT}"
	PHP_FPM_PORT="${PHP_FPM_DEFAULT_PORT}"
fi
# Apply Port
run "sed -i'' 's|^listen[[:space:]]*=.*$|listen = 0.0.0.0:${PHP_FPM_PORT}|g' ${PHP_FPM_POOL_CONF}"



##
## PHP-FPM Xdebug
##

# Get xdebug config
XDEBUG_CONFIG="$( find /etc/php.d -name \*xdebug\*.ini )"


if set | grep '^PHP_ENABLE_XDEBUG=' >/dev/null 2>&1; then

	# ---- 1/3 Enabled ----
	if [ "${PHP_ENABLE_XDEBUG}" = "1" ]; then

		# 1.1 Check Xdebug Port
		if ! set | grep '^PHP_XDEBUG_REMOTE_PORT=' >/dev/null 2>&1; then
			echo >&2 "\$PHP_XDEBUG_REMOTE_PORT not set, defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"

		elif ! isint "${PHP_XDEBUG_REMOTE_PORT}"; then
			echo >&2 "\$PHP_XDEBUG_REMOTE_PORT is not a valid integer: ${PHP_XDEBUG_REMOTE_PORT}"
			echo >&2 "\Defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"

		elif [ "${PHP_XDEBUG_REMOTE_PORT}" -lt "1" ] || [ "${PHP_XDEBUG_REMOTE_PORT}" -gt "65535" ]; then
			echo >&2 "\$PHP_XDEBUG_REMOTE_PORT is out of range: ${PHP_XDEBUG_REMOTE_PORT}"
			echo >&2 "\Defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"
		fi

		# 1.2 Check Xdebug remote Host (IP address of Docker Host [your computer])
		if ! set | grep '^PHP_XDEBUG_REMOTE_HOST=' >/dev/null 2>&1; then
			echo >&2 "\$PHP_XDEBUG_REMOTE_HOST not set, but required."
			echo >&2 "\$PHP_XDEBUG_REMOTE_HOST should be the IP of your Host with the IDE to which xdebug can connect."
			exit 1
		fi

		# 1.3 Check if Xdebug config exists
		if [ ! -f "${XDEBUG_CONFIG}" ]; then
			echo >&2 "ERROR, no xdebug configuration found."
			echo >&2 "This should not happen."
			echo >&2 "Please file a bug at github."
			exit 1
		fi

		# 1.4 Enable Xdebug
		run "echo 'xdebug.remote_enable=1'							>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_connect_back=0'					>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_port=${PHP_XDEBUG_REMOTE_PORT}'	>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_host=${PHP_XDEBUG_REMOTE_HOST}'	>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_autostart=1'						>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_handler=dbgp'						>> ${XDEBUG_CONFIG}"
		run "echo 'xdebug.remote_log=\"/var/log/php-fpm/xdebug.log\"' >> ${XDEBUG_CONFIG}"


	# ---- 2/3 Disabled ----
	elif [ "${PHP_ENABLE_XDEBUG}" = "0" ]; then
		run "rm -f ${XDEBUG_CONFIG}"


	# ---- 3/3 Wrong value ----
	else
		echo >&2 "Invalid value for \$PHP_ENABLE_XDEBUG: ${PHP_ENABLE_XDEBUG}"
		echo >&2 "Must be '1' (for On) or '0' (for Off)"
		exit 1
	fi

else
	# Disable Xdebug
	if [ -f "${XDEBUG_CONFIG}" ]; then
		run "rm -f ${XDEBUG_CONFIG}"
	fi

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
