#!/usr/bin/env bash
# {{ ansible_managed }}

set -euo pipefail

mysql_data_dir="{{ mysql_server_datadir }}"

function backup_report {
  backup_file=$1
  RC=$?
  if [ ${RC} -gt 0 ]; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S.%N%:z' | sed 's/\([0-9]\{6\}\)[0-9]*/\1/') 0 [Error] [mysql-backup] An error occured during backup"
    exit ${RC}
  else
    echo "$(date '+%Y-%m-%dT%H:%M:%S.%N%:z' | sed 's/\([0-9]\{6\}\)[0-9]*/\1/') 0 [Note] [mysql-backup] Backup successful. File: ${backup_file}"
  fi
}

function backup_xbstream {
  backup_file="{{ _mysql_backup_dir }}/{{ inventory_hostname_short }}/mysql-$(date '+%Y.%m.%d.%H%M%S').xbstream"
  backup_dir="$(dirname "${backup_file}")"
  mkdir -p "${backup_dir}"
  echo "$(date '+%Y-%m-%dT%H:%M:%S.%N%:z' | sed 's/\([0-9]\{6\}\)[0-9]*/\1/') 0 [Note] [mysql-backup] Taking filesystem backup (xtrabackup) on master server"
  xtrabackup --backup \
    --datadir="${mysql_data_dir}" \
    --stream=xbstream \
    --compress --target-dir="${backup_dir}" >"${backup_file}"
  backup_report "${backup_file}"
}

function backup_mysqldump {
  backup_file="{{ _mysql_backup_dir }}/{{ inventory_hostname_short }}/mysql-$(date '+%Y.%m.%d.%H%M%S').sql.gz"
  mkdir -p "$(dirname "${backup_file}")"
  echo "$(date '+%Y-%m-%dT%H:%M:%S.%N%:z' | sed 's/\([0-9]\{6\}\)[0-9]*/\1/') 0 [Note] [mysql-backup] Taking logical backup (mysqldump) on master server"
  mysqldump \
    --all-databases --set-gtid-purged=OFF \
    --triggers --routines --events --quick --skip-lock-tables \
    --single-transaction | gzip >"${backup_file}"
  backup_report "${backup_file}"
}

function main {
  is_slave=$(mysql -Ns -e "SELECT @@global.read_only;")
  backup_xbstream
  if ((is_slave > 0)); then
    backup_mysqldump
  fi
}

main "$@"
