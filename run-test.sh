#!/bin/bash

if [ ! -f ".env.test" ]; then
    cp sample.env.test .env.test
    echo ".env.test létrehozva a sample.env.test alapján."
else
    echo ".env.test már létezik, nem másoltuk."
fi

PG_PASSWORD="POSTGRES_PASSWORD"
if grep -q "^$PG_PASSWORD=[^[:space:]]" .env.test 2>/dev/null; then
    echo "$PG_PASSWORD már rendelkezik értékkel, nem módosítottuk."
else
    PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    if grep -q "^$PG_PASSWORD=" .env.test 2>/dev/null; then
        sed -i "s/^$PG_PASSWORD=.*/$PG_PASSWORD=$PASSWORD/" .env.test
    else
        echo "$PG_PASSWORD=$PASSWORD" >> .env.test
    fi
    echo "$PG_PASSWORD jelszó létrehozva: $PASSWORD"
fi

PG_USER="POSTGRES_USER"
if grep -q "^$PG_USER=[^[:space:]]" .env.test 2>/dev/null; then
    echo "$PG_USER már rendelkezik értékkel, nem módosítottuk."
else
    USER=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    if grep -q "^$PG_USER=" .env.test 2>/dev/null; then
        sed -i "s/^$PG_USER=.*/$PG_USER=$USER/" .env.test
    else
        echo "$PG_USER=$USER" >> .env.test
    fi
    echo "$PG_USER felhasználó létrehozva: $USER"
fi

DB_URL="DATABASE_URL"
U=$(grep "^POSTGRES_USER=" .env.test | cut -d'=' -f2)
P=$(grep "^POSTGRES_PASSWORD=" .env.test | cut -d'=' -f2)
H=$(grep "^POSTGRES_HOST=" .env.test | cut -d'=' -f2)
PORT=$(grep "^POSTGRES_PORT=" .env.test | cut -d'=' -f2)
DB=$(grep "^POSTGRES_DATABASE=" .env.test | cut -d'=' -f2)
VAL="postgresql://$U:$P@$H:5432/$DB?schema=public"

if grep -q "^$DB_URL=" .env.test 2>/dev/null; then
    sed -i "s|^$DB_URL=.*|$DB_URL=$VAL|" .env.test
    echo "$DB_URL frissítve az .env.test fájlban."
else
    echo "$DB_URL=$VAL" >> .env.test
    echo "$DB_URL hozzáadva az .env.test fájlhoz."
fi

docker build --no-cache -t campuslife-backend -f docker/backend.Dockerfile apps/backend
docker build --no-cache -t campuslife-frontend -f docker/frontend.Dockerfile apps/frontend

echo "Images built successfully."

docker compose -p campuslife-test -f docker-compose.test.yml --env-file .env.test up --force-recreate
