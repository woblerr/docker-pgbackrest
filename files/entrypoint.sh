#!/usr/bin/env bash

uid=$(id -u)
su_command="gosu"
# Check user-spec command
[ "$(grep -E "^ID=" /etc/os-release | cut -d'=' -f2)" == "alpine" ] && su_command="su-exec"
# Execution command.
backrest_command="pgbackrest"
# Defaule pgbackrest user home
backrest_home="/home/${BACKREST_USER}"

if [ "${uid}" = "0" ]; then
    # Exec pgBackRest from specific user.
    backrest_command="${su_command} ${BACKREST_USER} pgbackrest"
    # Custom time zone.
    if [ "${TZ}" != "Europe/Moscow" ]; then
        cp /usr/share/zoneinfo/${TZ} /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
    # Check than custom user may already have home dir.
    home_exist="$(getent passwd ${BACKREST_USER} | cut -d: -f6)"
    if [ ! -z "${home_exist}" ]; then
        backrest_home=${home_exist}
    fi
    # Custom user group.
    if [ "${BACKREST_GROUP}" != "pgbackrest" ] || [ "${BACKREST_GID}" != "2001" ]; then
        groupmod -g ${BACKREST_GID} -n ${BACKREST_GROUP} pgbackrest
    fi
    # Custom user.
    if [ "${BACKREST_USER}" != "pgbackrest" ] || [ "${BACKREST_UID}" != "2001" ]; then
        usermod -g ${BACKREST_GID} -l ${BACKREST_USER} -u ${BACKREST_UID} -m -d ${backrest_home} pgbackrest
    fi
    # pgBackRest completion.
    echo "source /etc/bash_completion.d/pgbackrest-completion.sh" >> ${backrest_home}/.bashrc
    # Correct user:group.
    chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        ${backrest_home} \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest
fi

# Start docker container as pgBackRest TLS server.
if [ "${BACKREST_TLS_SERVER}" == "enable" ]; then
    exec ${backrest_command} server
fi

# Start TLS server in background for pgBackRest execution over TLS.
if [ "${BACKREST_HOST_TYPE}" == "tls" ] && [ "${BACKREST_TLS_SERVER}" == "disable" ]; then
    ${backrest_command} server &
    backrest_server_pid=$!
    # Wait TLS server start, by default - 15 sec.
    sleep ${BACKREST_TLS_WAIT}
    # Check process is running.
    ps -p ${backrest_server_pid} > /dev/null
    if [ "$?" != "0" ]; then
        echo "Error on TLS server startup, exit..."
        exit 1
    fi
fi

if [ "${uid}" = "0" ]; then
    exec ${su_command} ${BACKREST_USER} "$@"
else
    exec "$@"
fi
