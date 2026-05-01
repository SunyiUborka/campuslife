#!/bin/sh
set -e

mkdir -p /var/lib/pgadmin

printf 'postgres:5432:*:%s:%s\n' "$POSTGRES_USER" "$POSTGRES_PASSWORD" \
  > /var/lib/pgadmin/pgpass
chmod 600 /var/lib/pgadmin/pgpass

cat > /var/lib/pgadmin/servers.json << EOF
{
    "Servers": {
        "1": {
            "Name": "campuslife",
            "Group": "Servers",
            "Host": "postgres",
            "Port": 5432,
            "MaintenanceDB": "campuslife",
            "Username": "${POSTGRES_USER}",
            "Password": "${POSTGRES_PASSWORD}",
            "SSLMode": "prefer"
        }
    }
}
EOF

exec /entrypoint.sh "$@"
