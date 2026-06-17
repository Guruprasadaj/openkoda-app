#!/bin/bash
set -e

# Ubuntu/Debian keeps config under /etc/postgresql and data under /var/lib/postgresql.
# service postgresql start uses these paths; direct postgres -D alone does not.
PGDATA=/var/lib/postgresql/14/main
PGCONF=/etc/postgresql/14/main/postgresql.conf
PGHBA=/etc/postgresql/14/main/pg_hba.conf

exec /usr/lib/postgresql/14/bin/postgres \
  -D "${PGDATA}" \
  -c config_file="${PGCONF}" \
  -c hba_file="${PGHBA}"
