#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o posix

err() {
  echo >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $*"
}

echo_date() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

usage() {
  cat >&2 <<-EOF
Usage : $0 -d <directory> -l <db_name>
  -d dump directory destination (mandatory)
  -l list of db to dump (coma separated, mandatory)
  -k dumps to keep (in days)
  -h help
EOF
}

typeset VAR_DIR_ARGS=""
typeset VAR_DB_LIST_ARGS=""
typeset VAR_ROTATION_DAYS_ARGS=""

while getopts "d:l:k:h" OPTION; do
  case $OPTION in
    d)
      VAR_DIR_ARGS="$OPTARG"
      ;;
    l)
      VAR_DB_LIST_ARGS="$OPTARG"
      ;;
    k)
      VAR_ROTATION_DAYS_ARGS="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

[[ $VAR_DIR_ARGS != "" ]] || {
  usage
  exit 1
}
[[ $VAR_DB_LIST_ARGS != "" ]] || {
  usage
  exit 1
}

# remove eventual trailing slash
typeset -r VAR_DUMPS_DST_DIR=${VAR_DIR_ARGS%/}

if [[ ! -d $VAR_DUMPS_DST_DIR ]]; then
  mkdir -p "$VAR_DUMPS_DST_DIR" || {
    err "mkdir -p $VAR_DUMPS_DST_DIR"
    exit 1
  }
fi

for cmd in mysqldump gzip; do
  command -v "$cmd" >/dev/null || {
    err "$cmd command not found"
    exit 1
  }
done

for db in ${VAR_DB_LIST_ARGS//,/ }; do
  echo_date "start $db dump."
  DUMP_FILE=$VAR_DUMPS_DST_DIR/$db.$(date +%F_%H%M%S).sql
  mysqldump --single-transaction --quick --routines "$db" >"$DUMP_FILE"
  # shellcheck disable=SC2181
  if (($? != 0)); then
    err "unable do dump $db"
    exit 1
  fi
  echo_date "done.\n"
done

for sql in "$VAR_DUMPS_DST_DIR/"*.sql; do
  echo_date "compress $sql."
  gzip -- "$sql" || {
    err "gzip $sql"
    exit 1
  }
  echo_date "done.\n"
done

if [[ -n $VAR_ROTATION_DAYS_ARGS ]]; then
  # rotation
  echo "Rotation of old dumps (-${VAR_ROTATION_DAYS_ARGS}d)"
  if ! find "$VAR_DUMPS_DST_DIR" -name "*.sql.gz" -type f -mtime +"$((VAR_ROTATION_DAYS_ARGS - 1))" -exec /bin/rm -vf {} \;; then
    err "clean old dumps"
    exit 1
  fi
  echo -e "done.\n"
fi
