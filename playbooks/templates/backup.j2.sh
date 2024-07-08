#!/usr/bin/env bash
set -euo pipefail

datetime=$(date '+%Y.%m.%d.%H%M%S')
hostname=$(hostname -f)
root_backup_dir="{{ mysql_backup_dir }}"
host_backup_dir="$root_backup_dir/$hostname"
mysql_backup_retention_count="{{ mysql_backup_retention_count }}"
mysql_backup_retention_days="{{ mysql_backup_retention_days | default(mysql_backup_retention_count) }}"
mysql_backup_prune_days=$((mysql_backup_retention_days + 1))
is_slave=$(mysql -Ns -e "SELECT @@global.read_only;")

###########################
# Init backup destination #
###########################

mkdir -p "$host_backup_dir"

####################################
# Prune stale backup files by date #
####################################

mysql_backup_count="$(find "$host_backup_dir" -mindepth 1 -maxdepth 1 -type f -mtime "-$mysql_backup_prune_days" | wc -l)"
if (("$mysql_backup_count" > 1)); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up old backups files"
    find "$host_backup_dir" -mindepth 1 -maxdepth 1 -type f -mtime "+$mysql_backup_prune_days" \
        -exec echo "[$(date '+%Y-%m-%d %H:%M:%S')] DELETE: {}" \;
    find "$host_backup_dir" -mindepth 1 -maxdepth 1 -type f -mtime "+$mysql_backup_prune_days" \
        -delete
fi

#####################
# Filesystem backup #
#####################

if ((is_slave == 0)); then

    echo "========= MASTER NODE - ONLINE DB BACKUP ============"

    # Prune stale backup files by count
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up old backups files"
    cnt=1
    for f in $(ls -r ${host_backup_dir}/mysql-*.xbstream); do
        if [ ${cnt} -le ${mysql_backup_retention_count} ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEEP ${f}"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] DELETE ${f}"
            rm "${f}"
        fi
        echo "Next file ..."
        cnt=$((cnt + 1))
    done

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Taking filesystem backup (xtrabackup) on master server"
    # Take filesystem backup
    xtrabackup --backup \
        --no-server-version-check \
        --datadir="{{ mysql_db_datadir }}" \
        --stream=xbstream \
        --compress --target-dir="$host_backup_dir" >"$host_backup_dir/mysql-$datetime.xbstream"

    # Error handling
    RC=$?
    if [ $RC -gt 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: An error occured during backup (RC = $RC)"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Removing failed backup file: $host_backup_dir/mysql-$datetime.xbstream"
        rm "$host_backup_dir/mysql-$datetime.xbstream"
        exit 1
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Backup successful. File: $host_backup_dir/mysql-$datetime.xbstream"
    fi
fi

##################
# Logical backup #
##################

if ((is_slave > 0)); then

    echo "========= SLAVE NODE - LOGICAL BACKUP ============"

    # Prune stale backup files by count
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up old backups files"
    cnt=1
    for f in $(ls -r ${host_backup_dir}/mysql-*.sql.gz); do
        if [ ${cnt} -le ${mysql_backup_retention_count} ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEEP ${f}"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] DELETE ${f}"
            rm "${f}"
        fi
        echo "Next file ..."
        cnt=$((cnt + 1))
    done

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Taking logical backup (mysqldump) on slave server"
    # Take logical backup
    mysqldump \
        --all-databases \
        --triggers --routines --events --quick --skip-lock-tables \
        --single-transaction | gzip >"$host_backup_dir/mysql-$datetime.sql.gz"

    # Error handling
    RC=$?
    if [ $RC -gt 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Backup failed. An error occured during backup (RC = $RC)"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Removing failed backup file: $host_backup_dir/mysql-$datetime.sql.gz"
        rm "$host_backup_dir/mysql-$datetime.sql.gz"
        exit 1
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Backup successful: File: $host_backup_dir/mysql-$datetime.sql.gz"
    fi
fi
