#!/usr/bin/env sh

#set -x

TASKD_UID=${PUID:-5000}
TASKD_GID=${PGID:-5000}

CLIENT_ORG=${TASKD_USER_ORG:-test}
CLIENT_FIRST=${TASKD_USER_FIRST:-test}
CLIENT_LAST=${TASKD_USER_LAST:-test}

# TASKDDATA must exists

addgroup -g ${TASKD_GID} taskd
adduser -S -s /sbin/nologin -u ${TASKD_UID} -h "/home/taskd" -G taskd taskd
usermod -u ${TASKD_UID} taskd

mkdir -p ${TASKDDATA}
chown -R ${TASKD_UID}:${TASKD_GID} ${TASKDDATA}
taskd init
taskd config --force server `hostname -f`:53589
# https://taskwarrior.org/news/news.20150511.html
taskd config --force log "-"

# TODO Generate certs check everything exists else stops
if [ ! -f ${TASKDDATA}/ca.cert.pem ]; then
    echo "Certificates files missing or NOT found in ${TASKDDATA}. Generating new certs..."
	# https://pkgs.alpinelinux.org/contents?branch=v3.4&name=taskd-pki&arch=x86&repo=main
    echo HOST `hostname -f`
    cat > /usr/share/taskd/pki/vars	 <<- EOM
BITS=4096
EXPIRATION_DAYS=365
ORGANIZATION="Docker Taskd"
CN=`hostname -f`
COUNTRY=ES
STATE="Región de Murcia"
LOCALITY="Murcia"
EOM

    cd /usr/share/taskd/pki
    ./generate

    cp /usr/share/taskd/pki/client.cert.pem ${TASKDDATA}
    cp /usr/share/taskd/pki/client.key.pem  ${TASKDDATA}
    cp /usr/share/taskd/pki/server.cert.pem ${TASKDDATA}
    cp /usr/share/taskd/pki/server.key.pem  ${TASKDDATA}
    cp /usr/share/taskd/pki/server.crl.pem  ${TASKDDATA}
    cp /usr/share/taskd/pki/ca.cert.pem     ${TASKDDATA}

    chown -R taskd:taskd ${TASKDDATA}
    # https://stackoverflow.com/questions/8633461/how-to-keep-environment-variables-when-using-sudo
    # https://bbs.archlinux.org/viewtopic.php?id=237151
	sudo -E -H -u taskd sh -c "taskd config"

	echo "Creating ORGANIZATION"
	taskd add org ${CLIENT_ORG}

	echo "Creating CLIENT for ORGANIZATION"
	echo "------------ KEEP THIS USER ID VALUE ----------------"
    taskd add user "${CLIENT_ORG}" "${CLIENT_FIRST} ${CLIENT_LAST}"
	echo "-----------------------------------------------------"

    cd /usr/share/taskd/pki
    ./generate.client ${CLIENT_FIRST}_${CLIENT_LAST}
    cp /usr/share/taskd/pki/${CLIENT_FIRST}_${CLIENT_LAST}.cert.pem ${TASKDDATA}
    cp /usr/share/taskd/pki/${CLIENT_FIRST}_${CLIENT_LAST}.key.pem  ${TASKDDATA}

    cd ${TASKDDATA}
    ls -t ${TASKDDATA}/orgs/${CLIENT_ORG}/users/ | head -1 > userid.key
    # chown -R ${TASKD_UID}:${TASKD_GID} ${TASKDDATA}
    chown -R taskd:taskd ${TASKDDATA}

else
    echo "Certificates found in ${TASKDDATA}. Continue..."
fi

taskd config --force client.cert ${TASKDDATA}/client.cert.pem
taskd config --force client.key ${TASKDDATA}/client.key.pem
taskd config --force server.cert ${TASKDDATA}/server.cert.pem
taskd config --force server.key ${TASKDDATA}/server.key.pem
taskd config --force server.crl ${TASKDDATA}/server.crl.pem
taskd config --force ca.cert ${TASKDDATA}/ca.cert.pem

sudo -E -H -u taskd sh -c "taskd server"
