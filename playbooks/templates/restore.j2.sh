#!/usr/bin/env bash
# {{ ansible_managed }}

set -euo pipefail

mysql_data_dir="{{ mysql_server_datadir }}"

function log {
  message="$1"
  echo "$(date '+%Y-%m-%dT%H:%M:%S.%N%:z' | sed 's/\([0-9]\{6\}\)[0-9]*/\1/') 0 [Note] [mysql-restore] ${message}"
}

function parse_args {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup_file>"
    exit 1
  else
    backup_file="$1"
  fi
}

function restore_xbstream {
  log "Restoring Xtrabackup from ${backup_file}"
  backup_file="$1"
  restore_dir=$(mktemp -d)
  systemctl stop mysql
  gid=$(stat -c %g "${mysql_data_dir}")
  uid=$(stat -c %u "${mysql_data_dir}")
  rm -rf "${mysql_data_dir:?}"/*
  xbstream -v -C "${restore_dir}" -x <"${backup_file}"
  xtrabackup --decompress --target-dir="${restore_dir}"
  xtrabackup --prepare --target-dir="${restore_dir}"
  xtrabackup --copy-back --target-dir="${restore_dir}"
  chown -R "${uid}":"${gid}" "${mysql_data_dir}"
  systemctl start mysql
  rm -rf "${restore_dir:?}"
  echo "dba.configureInstance('clusteradmin@localhost:3306')" > cluster.js
  echo "cluster= dba.createCluster('test_cluster')" >> cluster.js
  echo "cluster.addInstance('clusteradmin@${hostname}:3306')" >> cluster.js
  echo "cluster.status()" >> cluster.js
  mysqlsh \c clusteradmin@localhost:3306 --file cluster.js
  rm cluster.js
}

function restore_mysqldump {
  log "Restoring MySQL dump from ${backup_file}"
  backup_file="$1"
  zcat "${backup_file}" | mysql -u root
}

function main {
  parse_args "$@"
  if [[ ! -f "${backup_file}" ]]; then
    echo "Backup file not found: ${backup_file}"
    exit 1
  elif [[ "${backup_file}" =~ .*.xbstream ]]; then
    restore_xbstream "${backup_file}"
  elif [[ "${backup_file}" =~ .*.sql.gz ]]; then
    restore_mysqldump "${backup_file}"
  else
    echo "Unknown backup file type: ${backup_file}"
    exit 1
  fi
}

main "$@"
