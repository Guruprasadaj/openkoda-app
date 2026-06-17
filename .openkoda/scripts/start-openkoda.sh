#!/bin/bash
set -e

until pg_isready -h 127.0.0.1 -p 5432 -U postgres -d openkoda >/dev/null 2>&1; do
  sleep 0.5
done

PROFILES="openkoda"
if [ -n "${SPRING_PROFILES_EXTRA:-}" ]; then
  PROFILES="${PROFILES},${SPRING_PROFILES_EXTRA}"
fi

exec java \
  -Dloader.path=/BOOT-INF/classes \
  -Dspring.profiles.active="${PROFILES}" \
  -Dapplication.admin.email="${APPLICATION_ADMIN_EMAIL}" \
  -Dbase.url="${BASE_URL}" \
  -Dinit.admin.username="${INIT_ADMIN_USERNAME}" \
  -Dinit.admin.password="${INIT_ADMIN_PASSWORD}" \
  -Dinit.admin.firstName="${INIT_ADMIN_FIRSTNAME}" \
  -Dinit.admin.lastName="${INIT_ADMIN_LASTNAME}" \
  -Dfile.storage.filesystem.path="${FILE_STORAGE_FILESYSTEM_PATH}" \
  -Dlogging.file.name=/var/log/openkoda/openkoda.log \
  -Dfile.storage.type="${STORAGE_TYPE}" \
  -Dspring.config.location="${SPRING_CONFIG_LOCATION}" \
  -Dspring.datasource.url="${SPRING_DATASOURCE_URL}" \
  -Dspring.datasource.username="${SPRING_DATASOURCE_USERNAME}" \
  -Dspring.datasource.password="${SPRING_DATASOURCE_PASSWORD}" \
  -Dspring.mail.host=127.0.0.1 \
  -Dspring.mail.port=1025 \
  -Dsecure.cookie=false \
  -jar /app/openkoda.jar \
  --server.port=8080 --force -y
