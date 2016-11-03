#!/bin/bash
# Starts up MariaDB within the container.

# Stop on error
#set -xv

NEST_DATA_DIR=/data

if [[ -e /firstrun ]]; then
  . /scripts/first_run.sh
else
  . /scripts/normal_run.sh
fi

## Fetch a particular option from mysql's invocation.
#
# Usage: void mysqld_get_param option
mysqld_get_param() {
        mysqld --print-defaults \
                | tr " " "\n" \
                | grep -- "--$1" \
                | tail -n 1 \
                | cut -d= -f2
}

mysqld_status () {
    ping_output=`mysqladmin ping 2>&1`; ping_alive=$(( ! $? ))

    ps_alive=0
    pidfile=`mysqld_get_param pid-file`
    if [ -f "$pidfile" ] && ps `cat $pidfile` >/dev/null 2>&1; then ps_alive=1; fi

    if [ "$1" = "check_alive"  -a  $ping_alive = 1 ] ||
       [ "$1" = "check_dead"   -a  $ping_alive = 0  -a  $ps_alive = 0 ]; then
        return 0 # EXIT_SUCCESS
    else
        if [ "$2" = "warn" ]; then
            echo -e "$ps_alive processes alive and 'mysqladmin ping' resulted in\n$ping_output\n"
        fi
        return 1 # EXIT_FAILURE
    fi
}

wait_for_mysql_and_run_post_start_action() {
  # Wait for mysql to finish starting up first.

        # 6s was reported in #352070 to be too little
        for i in $(seq 1 "${MYSQLD_STARTUP_TIMEOUT:-60}"); do
                sleep 1
      		echo waiting for mysql ...
                if mysqld_status check_alive nowarn ; then break; fi
        done

#	while [ ! -f /var/run/mysqld/mysqld.sock ]
#	do
#      		echo waiting for mysql ...
#	  	sleep 5
#	done

      	echo mysql is ready!

  post_start_action
}

pre_start_action

wait_for_mysql_and_run_post_start_action &

# Start MariaDB
echo "Starting MariaDB..."
exec /usr/bin/mysqld_safe
