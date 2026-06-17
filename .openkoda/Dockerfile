FROM ubuntu:22.04

ARG OPENKODA_VERSION=1.7.1
ARG MAILPIT_VERSION=1.21.8
ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive \
    OPENKODA_VERSION=${OPENKODA_VERSION} \
    APP_USER=openkoda \
    APP_UID=20000 \
    APP_GID=20000 \
    SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/openkoda \
    SPRING_DATASOURCE_USERNAME=postgres \
    SPRING_DATASOURCE_PASSWORD=postgres \
    BASE_URL=http://localhost:8080/ \
    APPLICATION_ADMIN_EMAIL=admin@openkoda.local \
    INIT_ADMIN_USERNAME=admin \
    INIT_ADMIN_PASSWORD=admin123 \
    INIT_ADMIN_FIRSTNAME=Admin \
    INIT_ADMIN_LASTNAME=User \
    FILE_STORAGE_FILESYSTEM_PATH=/data \
    STORAGE_TYPE=database \
    SPRING_CONFIG_LOCATION=classpath:/,/config/

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      openjdk-17-jdk \
      maven \
      postgresql-14 \
      postgresql-client-14 \
      supervisor \
      unzip \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH="${TARGETARCH:-amd64}" && \
    curl -fsSL "https://github.com/axllent/mailpit/releases/download/v${MAILPIT_VERSION}/mailpit-linux-${ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin mailpit

RUN groupadd -r -g "${APP_GID}" "${APP_USER}" && \
    useradd -m -u "${APP_UID}" -g "${APP_GID}" -s /bin/bash "${APP_USER}"

COPY . /app/src

WORKDIR /app/src

RUN mvn -f openkoda/pom.xml clean install spring-boot:repackage -DskipTests -q && \
    JAR_PATH="$(find openkoda/build openkoda/target -maxdepth 1 -name '*.jar' ! -name '*-sources.jar' 2>/dev/null | head -n 1)" && \
    test -n "${JAR_PATH}" && \
    cp "${JAR_PATH}" /app/openkoda.jar

RUN mkdir -p /data /config /var/log/openkoda /openkoda/scripts && \
    cp /app/src/.openkoda/config/application-override.properties /config/application-override.properties && \
    cp /app/src/.openkoda/scripts/*.sh /openkoda/scripts/ && \
    chmod +x /openkoda/scripts/*.sh

# postgresql-14 package already provisions the 14/main cluster on install
RUN service postgresql start && \
    su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\"" && \
    su postgres -c "createdb openkoda" && \
    su "${APP_USER}" -c "java \
      -Dloader.path=/BOOT-INF/classes \
      -Dspring.profiles.active=openkoda,drop_and_init_database \
      -Dapplication.admin.email=${APPLICATION_ADMIN_EMAIL} \
      -Dinit.admin.username=${INIT_ADMIN_USERNAME} \
      -Dinit.admin.password=${INIT_ADMIN_PASSWORD} \
      -Dinit.admin.firstName=${INIT_ADMIN_FIRSTNAME} \
      -Dinit.admin.lastName=${INIT_ADMIN_LASTNAME} \
      -Dfile.storage.filesystem.path=${FILE_STORAGE_FILESYSTEM_PATH} \
      -Dlogging.file.name=/var/log/openkoda/openkoda.log \
      -Dfile.storage.type=${STORAGE_TYPE} \
      -Dspring.config.location=${SPRING_CONFIG_LOCATION} \
      -Dspring.datasource.url=${SPRING_DATASOURCE_URL} \
      -Dspring.datasource.username=${SPRING_DATASOURCE_USERNAME} \
      -Dspring.datasource.password=${SPRING_DATASOURCE_PASSWORD} \
      -Dsecure.cookie=false \
      -jar /app/openkoda.jar \
      --server.port=8080 --force -y" && \
    service postgresql stop

RUN cp /app/src/.openkoda/entrypoint.sh /openkoda/entrypoint.sh && \
    cp /app/src/.openkoda/supervisord.conf /etc/supervisor/conf.d/supervisord.conf && \
    chmod +x /openkoda/entrypoint.sh && \
    chown -R "${APP_USER}:${APP_USER}" /app/openkoda.jar /data /config /var/log/openkoda && \
    chown -R postgres:postgres /var/lib/postgresql

RUN rm -rf /app/src /root/.m2

WORKDIR /app

EXPOSE 8080 8025 1025

ENTRYPOINT ["/openkoda/entrypoint.sh"]
