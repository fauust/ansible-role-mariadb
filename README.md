# Ansible role: MariaDB

[![pre-commit](https://github.com/fauust/ansible-role-mariadb/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/fauust/ansible-role-mariadb/actions/workflows/pre-commit.yml)
[![Default](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_default.yml/badge.svg)](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_default.yml)
[![MDBF](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_mdbf.yml/badge.svg)](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_mdbf.yml)
[![Cluster](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_cluster.yml/badge.svg)](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_cluster.yml)
[![Cluster MDBF](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_cluster_mdbf.yml/badge.svg)](https://github.com/fauust/ansible-role-mariadb/actions/workflows/test_cluster_mdbf.yml)

Install and configure MariaDB Server on Debian/Ubuntu.

Optionally, this role also permits one to:

- deploy a primary/replica cluster;
- setup backups and rotation of the dumps.

## Requirements

The role uses
[`community.mysql.mysql_user`](https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_user_module.html)
and
[`community.mysql.mysql_db`](https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_db_module.html)
ansible modules that depend on [PyMySQL](https://github.com/PyMySQL/PyMySQL).
Only Python 3.X versions are supported and tested. Python 2.7 is probably
working but not tested.

If you need to deploy a cluster then you need Ansible 2.12+ since there was a
change in the
[`community.mysql.mysql_replication`](https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_replication_module.html)
naming for cluster node (primary/replica is now preferred).

### pre-commit

Any code submitted to this project is checked with the
[pre-commit](https://pre-commit.com/) framework. To make sure that your
code will pass the checks, you can execute the pre-commit checks locally before
"git pushing" your code.

Here is how:

```console
❯ make venv
❯ source .venv/bin/activate
.venv ❯ make install-pre-commit
.venv ❯ make pre-commit-run
```

You can also [install](https://pre-commit.com/#install) the pre-commit tool so
that any commit will be checked automatically.

### Testing (Molecule)

The role is tested with the [Molecule
project](https://molecule.readthedocs.io/en/latest/index.html). By default this
role will be tested with the `podman` driver, but you can easily adapt it to use
`docker` if you prefer.

Here is an example how you can test a deployment of MariaDB Server `10.6`
packaged by the MariaDB Foundation (MDBF) on `Almalinux 9`:

```console
❯ make install
❯ source .venv/bin/activate
.venv ❯ export MOLECULE_DISTRO=almalinux-9
.venv ❯ export MOLECULE_PLAYBOOK=converge-mdbf.yml
.venv ❯ export MARIADB_VERSION="10.6"
.venv ❯ molecule test
...
```

And here is another example how you can test a deployment of a MariaDB Server
cluster (3 nodes: 1 primary, 2 replica) on `fedora 37`:

```console
.venv ❯ export MOLECULE_DISTRO=fedora-37
.venv ❯ molecule test -s cluster
...
```

## Fact gathering (performance)

Fact gathering is only needed if you want to use the MariaDB official repository
(<https://mariadb.org/download/?t=repo-config>)

## Role variables

Available variables are listed below, along with default values (see
[`defaults/main.yml`](./defaults/main.yml)).

### MariaDB version

```yaml
mariadb_use_official_repo: false
mariadb_use_official_repo_url: https://deb.mariadb.org
mariadb_use_official_repo_version: "10.10"
```

You may deploy the MariaDB Server version that comes with your distribution
(Debian/Ubuntu) or deploy the version packaged by the MariaDB Foundation.
You can use the MariaDB Foundation repository configuration tool:
<https://mariadb.org/download/#mariadb-repositories>

By default, we deploy the MariaDB Server version that comes with the distribution.

### MariaDB service activation and restart

```yaml
mariadb_enabled_on_startup: true
mariadb_can_restart: true
```

**Warning:** you may consider setting `mariadb_can_restart` to `false` on
production systems to prevent ansible runs from restarting the MariaDB Server.

### General configuration

To populate the MariaDB Server configuration file, we use almost only raw
variables. This permits more flexibility and a very simple
[`templates/mariadb.cnf.j2`](./templates/mariadb.cnf.j2) file.

By default, some common and standard options are deployed based on the MariaDB
Foundation package. Those default values are only meant as an example and for testing
deployments and you are encouraged to use your own values.

#### Basic settings

`default value depends on OS` means that the value is overridden at OS level, see
[`vars`](./vars).

```yaml
mariadb_config_file: "default value depends on OS"
mariadb_data_dir: "default value depends on OS"
mariadb_port: 3306
mariadb_bind_address: 127.0.0.1
mariadb_unix_socket: "default value depends on OS"
```

```yaml
mariadb_basic_settings_raw: |
  user                  = mysql
  pid-file              = {{ mariadb_pid_file }}
  socket                = {{ mariadb_unix_socket }}
  basedir               = /usr
  datadir               = {{ mariadb_data_dir }}
  tmpdir                = /tmp
  lc-messages-dir       = /usr/share/mysql
  lc_messages           = en_US
  skip-external-locking
  port                  = {{ mariadb_port }}
  bind-address          = {{ mariadb_bind_address }}
```

#### Fine-tuning

```yaml
mariadb_fine_tuning_raw: |
  max_connections         = 100
  connect_timeout         = 5
  wait_timeout            = 600
  max_allowed_packet      = 16M
  thread_cache_size       = 128
  sort_buffer_size        = 4M
  bulk_insert_buffer_size = 16M
  tmp_table_size          = 32M
  max_heap_table_size     = 32M
```

#### Query cache

```yaml
mariadb_query_cache_raw: |
  query_cache_size        = 16M
```

#### Logging

```yaml
mariadb_logging_raw: |
  log_error = "default value depends on OS"
```

#### Character sets

```yaml
mariadb_character_sets_raw: |
  character-set-server = utf8mb4
  collation-server     = utf8mb4_general_ci
```

#### InnoDB

```yaml
mariadb_innodb_raw: |
  # InnoDB is enabled by default with a 10 MB datafile in /var/lib/mysql/.
  # Read the manual for more InnoDB related options. There are many!
```

#### Mariadbdump

```yaml
mariadb_mysqldump_raw: |
  quick
  quote-names
  max_allowed_packet = 16M
```

### Database management

```yaml
mariadb_databases: []
#   - name: db1
#     collation: utf8_general_ci
#     encoding: utf8
#     replicate: true|false
```

See: <https://docs.ansible.com/ansible/latest/modules/mysql_db_module.html>

### User management

```yaml
mariadb_users: []
#   - name: user
#     host: 100.64.200.10
#     password: password
#     priv: "*.*:USAGE/db1.*:ALL"
#     state: present|absent
```

See: <https://docs.ansible.com/ansible/latest/modules/mysql_user_module.html>

### Replication (optional)

Replication is only enabled if `mariadb_replication_role` has a value (`primary` or
`replica`).

The replication setup on the replica use the GTID autopositioning, see
<https://mariadb.com/kb/en/library/change-master-to/#master_use_gtid>

#### Common vars

```yaml
# Same keys as `mariadb_users` above.
# priv is set to "*.*:REPLICATION SLAVE" by default
mariadb_replication_user: []
```

#### Primary node variables

```yaml
mariadb_replication_role: primary
mariadb_server_id: 1
mariadb_max_binlog_size: 100M
mariadb_binlog_format: MIXED
mariadb_expire_logs_days: 10
```

#### Replica variables

```yaml
mariadb_replication_role: replica
mariadb_server_id: 1
mariadb_replication_primary_ip: IP
```

### Backups (optional)

```yaml
# db dumps backup
mariadb_backup_db: false
mariadb_backup_db_cron_min: 50
mariadb_backup_db_cron_hour: 00
mariadb_backup_db_dir: /mnt/backup
mariadb_backup_db_rotation: 15
# set to "1>" to get only STDERR on cron
mariadb_backup_cron_std_output: "2>&1 | tee"

# name of the database to dump
# (mandatory if mariadb_backup_db is set to true)
mariadb_backup_db_name: []
#   - db1
#   - db2
```

Database dumps are done serially and the compression step (`gzip`) is done after to
avoid lengthy locks.

## Example playbook

```yaml
- hosts: db
  roles:
    - fauust.mariadb
```

## Lincense

GNU General Public License v3.0
