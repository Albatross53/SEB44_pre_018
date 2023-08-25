FROM eclipse-temurin:11 as build

# build
WORKDIR /app
COPY . /app

RUN if [ -f "./gradlew" ]; then chmod +x ./gradlew; fi
RUN --mount=type=cache,id=test-gradle,target=/root/.gradle ./gradlew clean bootjar -x test --build-cache -i -s --no-daemon

# runner
FROM eclipse-temurin:11-jre

RUN set -o errexit -o nounset \
  && groupadd --system --gid 1000 java \
  && useradd --system --gid java --uid 1000 --shell /bin/bash --create-home java

WORKDIR /app
COPY --from=build --chown=java:java /app/ .

ENV JWT_SECRET_KEY ${JWT_SECRET_KEY}
ENV MARIADB_HOST ${MARIADB_HOST}
ENV MARIADB_USER ${MARIADB_USER}
ENV MARIADB_PASSWORD ${MARIADB_PASSWORD}

USER java

CMD java -jar -Dspring.profiles.active=${PROFILE} `find . -type f -name "*.jar" ! -path "*-plain.jar" ! -path "*-wrapper.jar" | head -1`