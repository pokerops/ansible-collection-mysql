# Ansible Collection - pokerops.mysql

[![Build Status](https://github.com/pokerops/ansible-collection-mysql/actions/workflows/molecule.yml/badge.svg)](https://github.com/pokerops/ansible-collection-mysql/actions/wofklows/molecule.yml)
[![Ansible Galaxy](http://img.shields.io/badge/ansible--galaxy-pokerops.mysql-blue.svg)](https://galaxy.ansible.com/ui/repo/published/pokerops/mysql/)

An [Ansible collection](https://galaxy.ansible.com/ui/repo/published/nephelaiio/mysql/) to install and manage [MySQL](https://www.mysql.com/) InnoDB clusters

## ToDo

* Add cluster failover deployment option and test scenario
* Add database and user management to install scenario
* Add Debian to test targets
* Add support for RockyLinux / AlmaLinux
* Split cluster and repo roles to separate repositories

## Collection hostgroups

| Hostgroup           |         Default | Description        |
|:--------------------|----------------:|:-------------------|
| mysql_cluster_group | 'mysql_cluster' | MySQL DBMS hosts   |
| mysql_router_group  |   'mysql_router | MySQL router hosts |

## Collection variables

The following is the list of parameters intended for end-user customization: 

| Parameter                   |                     Default | Description                                       | Required |
|:----------------------------|----------------------------:|:--------------------------------------------------|:---------|
| mysql_cluster_name          |                         N/A | MySQL InnoDB cluster name                         | true     |
| mysql_root_password         |                         N/A | MySQL root password                               | true     |
| mysql_router_password       |                         N/A | MySQL router password                             | true     |
| mysql_clusteradmin_password |                         N/A | MySQL clusteradmin password                       | true     |
| mysql_release               |                         8.0 | Target PostgreSQL release in 'major.minor' format | false    |
| mysql_cluster_packages      |                         N/A | Target PostgreSQL packages                        | false    |
| mysql_config_hostnames      |                        true | Toggle flag for /etc/hosts record configuration   | false    |
| mysql_backup_dir            |                     /backup | Destination directory for mysql backups           | false    |
| mysql_backup_bin            | /usr/local/bin/mysql-backup | Destination directory for mysql backups           | false    |
| mysql_config_overrides      |                         N/A | Configuration override fragment for MySQL daemon  | false    |
| mysql_backup_cron_min       |                          00 | Backup crontab minute                             | false    |
| mysql_backup_cron_hour      |                          04 | Backup crontab hour                               | false    |
| mysql_backup_cron_dow       |                          ** | Backup crontab days of week                       | false    |

Additionally parameters from Geerlinguy's MySQL [role](https://github.com/geerlingguy/ansible-role-mysql) will be passed down to the wrapped role with the same semantics with cluster-aware operation

## Collection playbooks

* nephelaiio.patroni.install: Install and bootstrap cluster
* nephelaiio.patroni.update: Update cluster OS

## Testing

Please make sure your environment has [docker](https://www.docker.com) installed in order to run role validation tests.

Role is tested against the following distributions (docker images):

  * Ubuntu Jammy
  * Ubuntu Focal

You can test the collection directly from sources using command `make test`

## License

This project is licensed under the terms of the [MIT License](/LICENSE)

