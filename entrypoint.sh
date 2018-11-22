#!/bin/bash

# Set Configuration for Teamspeak in ts3server.ini
# The following Lines will set the ts3server.ini

cat > ts3server.ini <<EOF
logquerycommands=${LOG_QUERY_COMMANDS:-0}
machine_id=${MACHINE_ID:-}
default_voice_port=${DEFAULT_VOICE_PORT}
voice_ip=${VOICE_IP:-0.0.0.0}
licensepath=${TS3_LICENSE_PATH}
filetransfer_port=${FILE_TRANSFER_PORT}
filetransfer_ip=${FILE_TRANSFER_IP:-0.0.0.0}
query_port=${QUERY_PORT}
query_ip=${QUERY_IP:-0.0.0.0}
query_ip_whitelist=${QUERY_IP_WHITELIST:-query_ip_whitelist.txt}
query_ip_blacklist=${QUERY_IP_BLACKLIST:-query_ip_blacklist.txt}
EOF

# This checks if it should run with an external MariaDB
# or SQL_LITE
if [[ -n "${TS3_MARIADB_DB}" ]] && [[ -n "${TS3_MARIADB_HOST}" ]] && [[ -n "${TS3_MARIADB_USER}" ]] && [[ -n "${TS3_MARIADB_PASS}" ]]; then

cat <<EOF >> ts3server.ini
dbplugin=ts3db_mariadb
dbpluginparameter=ts3db_mariadb.ini
dbsqlpath=sql/
dbsqlcreatepath=create_mariadb
EOF

# Wait until database is ready
until mysql \
        -h "${TS3_MARIADB_HOST}" \
        -u "${TS3_MARIADB_USER}" \
        -p "${TS3_MARIADB_PASS}" \
        -P "${TS3_MARIADB_PORT}" \
        -d "${TS3_MARIADB_DB}" ; \
do sleep 1 ; \
done

# Begin ts3db_mariadb.ini
# This writes the database settings for MariaDB
cat > ts3db_mariadb.ini <<EOF
[config]
host=${TS3_MARIADB_HOST}
port=${TS3_MARIADB_PORT}
username=${TS3_MARIADB_USER}
password=${TS3_MARIADB_PASS}
database=${TS3_MARIADB_DB}
socket=
EOF
# end ts3db_mariadb.ini

else

cat <<EOF >> ts3server.ini
dbplugin=ts3db_sqlite3
dbpluginparameter=
dbsqlpath=sql/
dbsqlcreatepath=create_sqlite/
dbconnections=10
EOF

fi

cat >> ts3server.ini <<EOF
logpath=${LOG_PATH:-logs}
logquerycommands=${LOG_QUERY_COMMAND:-0}
dbclientkeepdays=${DB_CLIENT_KEEP_DAYS:-30}
logappend=${LOG_APPEND:-0}
query_skipbruteforcecheck=${QUERY_SKIP_BRUTEFORCE_CHECK:-0}
EOF

# End ts3server.ini

# Run Teamspeak server
exec ./ts3server_minimal_runscript.sh inifile=ts3server.ini
