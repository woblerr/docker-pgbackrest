ARG BACKREST_VERSION="2.48"

FROM pgbackrest:${BACKREST_VERSION}
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-utils \
        openssh-server \
        rsyslog \
    && mkdir -p -m 700 \
        /home/${BACKREST_USER}/.ssh \
        /home/${BACKREST_USER}/sshd \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /home/${BACKREST_USER}/.ssh \
        /home/${BACKREST_USER}/sshd \
    && apt-get autoremove -y \
    && apt-get autopurge -y \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/sftp/sftp_prepare.sh /home/${BACKREST_USER}/sftp_prepare.sh
COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/ssh/authorized_keys /home/${BACKREST_USER}/.ssh/authorized_keys
COPY --chmod=700 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./conf/sftp/sshd /home/${BACKREST_USER}/sshd
ENTRYPOINT ["/entrypoint.sh"]
