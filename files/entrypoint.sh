#! /bin/sh

uid=$(id -u)

if [ "${uid}" = "0" ]; then
    # Custom time zoneuid
    if [ "${TZ}" != "Europe/Moscow" ]; then
        cp /usr/share/zoneinfo/${TZ} /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
    # Custom user group
    if [ "${BACKREST_GROUP}" != "pgbackrest" ] || [ "${BACKREST_GID}" != "2001" ]; then
        groupmod -g ${BACKREST_GID} -n ${BACKREST_GROUP} pgbackrest
    fi
    # Custom user
    if [ "${BACKREST_USER}" != "pgbackrest" ] || [ "${BACKREST_UID}" != "2001" ]; then
        usermod -g ${BACKREST_GID} -l ${BACKREST_USER} -u ${BACKREST_UID} -m -d /home/${BACKREST_USER} pgbackrest
    fi
    # Correct user:group
    chown -R ${BACKREST_USER}:${BACKREST_GROUP} /var/log/pgbackrest /etc/pgbackrest
    # pgBackRest completion
    echo "source /etc/bash_completion.d/pgbackrest-completion.sh" >> /home/${BACKREST_USER}/.bashrc
    exec gosu ${BACKREST_USER} "$@"
else
    exec "$@"
fi

