#!/bin/bash
set -e

#
# Display settings on standard out.
#

USER="sabnzbd"

echo "SABnzbd settings"
echo "================"
echo
echo "  User:       ${USER}"
echo "  UID:        ${SABNZBD_UID:=666}"
echo "  GID:        ${SABNZBD_GID:=666}"
echo
echo "  Config:     ${CONFIG:=/datadir/config.ini}"
echo

#
# Change UID / GID of SABnzbd user.
#

printf "Updating UID / GID... "
[[ $(id -u ${USER}) == ${SABNZBD_UID} ]] || usermod  -o -u ${SABNZBD_UID} ${USER}
[[ $(id -g ${USER}) == ${SABNZBD_GID} ]] || groupmod -o -g ${SABNZBD_GID} ${USER}
echo "[DONE]"

#
# Set directory permissions.
#

printf "Set permissions... "
touch ${CONFIG}
chown -R ${USER}: /sabnzbd
function check_dir {
  [ "$(stat -c '%u %g' $1)" == "${SABNZBD_UID} ${SABNZBD_GID}" ] || chown ${USER}: $1
}
check_dir /datadir
check_dir /media
check_dir $(dirname ${CONFIG})
echo "[DONE]"

#
# Because SABnzbd runs in a container we've to make sure we've a proper
# listener on 0.0.0.0. We also have to deal with the port which by default is
# 8080 but can be changed by the user.
#

printf "Get listener port... "
PORT=$(sed -n '/^port *=/{s/port *= *//p;q}' ${CONFIG})
LISTENER="-s 0.0.0.0:${PORT:=8080}"
echo "[${PORT}]"

#
# Update the host_whitelist setting (see https://sabnzbd.org/hostname-check)
# with any additional hostname/fqdn entries supplied via the HOST_WHITELIST_ENTRIES
# env variable.
#

if [[ -n ${HOST_WHITELIST_ENTRIES} ]];
then
    printf "Updating host_whitelist setting ... "
    sed -i -e "s/^host_whitelist *=.*$/host_whitelist = ${HOSTNAME}, ${HOST_WHITELIST_ENTRIES}/g" ${CONFIG}
    HOST_WHITELIST=$(sed -n '/^host_whitelist *=/{s/host_whitelist *= *//p;q}' ${CONFIG})
    echo "[${HOST_WHITELIST}]"
fi


#
# Finally, start SABnzbd.
#

echo "Starting SABnzbd..."
exec su -pc "python SABnzbd.py -b 0 -f ${CONFIG} ${LISTENER}" ${USER}
