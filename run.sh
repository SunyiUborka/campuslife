#!/bin/bash

if [ ! -f ".env" ]; then
    cp sample.env .env
    echo ".env létrehozva a sample.env alapján."
else
    echo ".env már létezik, nem másoltuk."
fi

PG_PASSWORD="POSTGRES_PASSWORD"
if grep -q "^$PG_PASSWORD=[^[:space:]]" .env 2>/dev/null; then
    echo "$PG_PASSWORD már rendelkezik értékkel, nem módosítottuk."
else
    PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    if grep -q "^$PG_PASSWORD=" .env 2>/dev/null; then
        sed -i "s/^$PG_PASSWORD=.*/$PG_PASSWORD=$PASSWORD/" .env
    else
        echo "$PG_PASSWORD=$PASSWORD" >> .env
    fi
    echo "$PG_PASSWORD jelszó létrehozva: $PASSWORD"
fi

PG_USER="POSTGRES_USER"
if grep -q "^$PG_USER=[^[:space:]]" .env 2>/dev/null; then
    echo "$PG_USER már rendelkezik értékkel, nem módosítottuk."
else
    PG_USER_VALUE=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    if grep -q "^$PG_USER=" .env 2>/dev/null; then
        sed -i "s/^$PG_USER=.*/$PG_USER=$PG_USER_VALUE/" .env
    else
        echo "$PG_USER=$PG_USER_VALUE" >> .env
    fi
    echo "$PG_USER felhasználó létrehozva: $PG_USER_VALUE"
fi

DB_URL="DATABASE_URL"
# Get current values from .env
U=$(grep "^POSTGRES_USER=" .env | cut -d'=' -f2)
P=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2)
H=$(grep "^POSTGRES_HOST=" .env | cut -d'=' -f2)
PORT=$(grep "^POSTGRES_PORT=" .env | cut -d'=' -f2)
DB=$(grep "^POSTGRES_DATABASE=" .env | cut -d'=' -f2)
VAL="postgresql://$U:$P@$H:$PORT/$DB?schema=public"

if grep -q "^$DB_URL=" .env 2>/dev/null; then
    sed -i "s|^$DB_URL=.*|$DB_URL=$VAL|" .env
    echo "$DB_URL frissítve az .env fájlban."
else
    echo "$DB_URL=$VAL" >> .env
    echo "$DB_URL hozzáadva az .env fájlhoz."
fi

docker build --no-cache -t campuslife-backend -f docker/backend.Dockerfile apps/backend
docker build --no-cache -t campuslife-frontend -f docker/frontend.Dockerfile apps/frontend

echo "Images built successfully."

export PUID=$(id -u)
export PGID=$(id -g)

docker network create caddy 2>/dev/null || true

docker compose up --force-recreate
