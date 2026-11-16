#!/bin/bash

set -e

: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${POSTGRES_REPLICATION_PASSWORD:?POSTGRES_REPLICATION_PASSWORD is required}"

# A data directory without standby.signal means a previous run fell through to
# a standalone initdb (or the basebackup was interrupted). Serving that copy
# silently diverges from the primary, so refuse to start instead.
if [ -n "$(ls -A "$PGDATA" 2>/dev/null)" ] && [ ! -f "$PGDATA/standby.signal" ]; then
	echo "FATAL: $PGDATA is non-empty but has no standby.signal; refusing to start a stale standalone copy" >&2
	exit 1
fi

while ! PGPASSWORD="${POSTGRES_PASSWORD}" psql -h primary -U "$POSTGRES_USER" -d "$POSTGRES_DB" -p 5432 -c "select 'it is running';" 2>&1 ; do \
	sleep 1s ; \
done

primary_query() {
	PGPASSWORD="${POSTGRES_PASSWORD}" psql -h primary -U "$POSTGRES_USER" -d "$POSTGRES_DB" -p 5432 -Atqc "$1"
}

# Resume an existing standby instead of re-cloning the whole primary on every start (a full
# pg_basebackup copies every database, about 12 GB for Access). Resuming is safe only when the
# copy still belongs to this primary and the primary kept the WAL it needs:
#   - the system identifier matches (a recreated primary volume has a new one), and
#   - the replication slot still reserves WAL (restart_lsn set, wal_status not "lost";
#     max_slot_wal_keep_size invalidates the slot when a stopped replica falls too far behind).
# Otherwise discard the copy and clone again below.
if [ -f "$PGDATA/standby.signal" ]; then
	local_id=$(pg_controldata "$PGDATA" 2>/dev/null | awk -F': *' '/^Database system identifier/{print $2}')
	primary_id=$(primary_query "select system_identifier from pg_control_system()")
	slot_ok=$(primary_query "select count(*) from pg_replication_slots
		where slot_name = 'replication_slot_slave1' and restart_lsn is not null
		and wal_status in ('reserved', 'extended', 'unreserved')")
	if [ -n "$local_id" ] && [ "$local_id" = "$primary_id" ] && [ "$slot_ok" = 1 ]; then
		echo "Resuming the existing standby (system identifier ${local_id}, slot reserves WAL)"
		exec bash /usr/local/bin/docker-entrypoint.sh -c 'config_file=/etc/postgresql/postgresql.conf' -c 'hba_file=/etc/postgresql/pg_hba.conf'
	fi
	echo "Existing standby cannot resume (local id '${local_id}', primary id '${primary_id}', slot ok '${slot_ok}'); re-cloning" >&2
	rm -rf "${PGDATA:?}"/* "${PGDATA:?}"/.[!.]* 2>/dev/null || true
fi

# Clone from the primary. A failed basebackup must not fall through to the
# stock entrypoint: with an empty PGDATA that would initdb a standalone
# writable instance, orphaning the primary's replication slot (which then
# retains WAL without bound). Retry a few times, then exit so compose
# restarts the container.
basebackup_attempts=5
for attempt in $(seq 1 "$basebackup_attempts"); do
	if PGPASSWORD="${POSTGRES_REPLICATION_PASSWORD}" pg_basebackup \
		-h primary \
		-p 5432 \
		-D "$PGDATA" \
		-S replication_slot_slave1 \
		--progress \
		-X stream \
		-U "$POSTGRES_REPLICATION_USER" \
		-Fp \
		-R; then
		break
	fi
	echo "pg_basebackup attempt ${attempt}/${basebackup_attempts} failed" >&2
	if [ "$attempt" -eq "$basebackup_attempts" ]; then
		echo "FATAL: pg_basebackup failed ${basebackup_attempts} times; exiting for container restart" >&2
		exit 1
	fi
	# pg_basebackup removes its own partial contents on failure, but clear any
	# leftovers so the next attempt starts from an empty directory.
	rm -rf "${PGDATA:?}"/* "${PGDATA:?}"/.[!.]* 2>/dev/null || true
	sleep 3s
done

# start postgres. exec so PostgreSQL receives the stop signal (SIGINT) directly; as a child of
# this script it ignored `podman stop` until the timeout forced a SIGKILL.
exec bash /usr/local/bin/docker-entrypoint.sh -c 'config_file=/etc/postgresql/postgresql.conf' -c 'hba_file=/etc/postgresql/pg_hba.conf'
