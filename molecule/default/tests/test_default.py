import os

# pylint: disable=import-error
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_passwd_file(host):
    passwd = host.file("/etc/passwd")
    assert passwd.contains("mysql")
    assert passwd.user == "root"
    assert passwd.group == "root"


def test_mariadb_is_installed(host):
    package = host.package("mariadb-server")
    assert package.is_installed


def test_ensure_mariadb_is_listening_on_requiered_port(host):
    assert host.socket("tcp://0.0.0.0:3306").is_listening


def test_mariadb_enabled_and_running(host):
    assert host.service("mariadb").is_running
    assert host.service("mariadb").is_enabled


def test_ensure_custom_config_is_applied(host):
    config = host.file("/etc/mysql/my.cnf")
    assert config.contains("datadir")
    assert config.user == "root"
    assert config.group == "root"
    assert config.mode == 0o644


def test_ensure_innodb_is_enabled(host):
    assert host.run("mariadb -Bse 'SHOW ENGINES' |\
            grep -qE '^InnoDB.DEFAULT.*YES.YES.YES$'").rc == 0


def test_ensure_system_db_exist(host):
    assert host.run("mariadb -Bse 'SHOW DATABASES' |\
            grep -q '^mysql$'").rc == 0
    assert host.run("mariadb -Bse 'SHOW DATABASES' |\
            grep -q '^information_schema$'").rc == 0
    assert host.run("mariadb -Bse 'SHOW DATABASES' |\
            grep -q '^performance_schema$'").rc == 0


def test_ensure_test_db_exist(host):
    assert host.run("mariadb -Bse 'SHOW DATABASES' |\
            grep -q '^db1'").rc == 0
    assert host.run("mariadb -Bse 'SHOW DATABASES' |\
            grep -q '^db2'").rc == 0


def test_some_sql_queries(host):
    assert host.run("mariadb -e 'CREATE DATABASE db'").rc == 0
    assert host.run("mariadb -e 'CREATE TABLE\
            db.t_innodb(a1 SERIAL, c1 CHAR(8)) ENGINE=InnoDB;\
            INSERT INTO db.t_innodb VALUES (1,\"foo\"),(2,\"bar\")'").rc == 0
    assert host.run("mariadb -e 'CREATE FUNCTION db.f()\
            RETURNS INT DETERMINISTIC RETURN 1'").rc == 0
    assert host.run("mariadb -e 'SHOW TABLES IN db'").rc == 0
    assert host.run("mariadb -e 'SELECT * FROM db.t_innodb;\
            INSERT INTO db.t_innodb VALUES (3,\"foo\"),(4,\"bar\")'").rc == 0
    assert host.run("mariadb -e 'SELECT db.f()'").rc == 0
