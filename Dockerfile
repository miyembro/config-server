FROM docker.io/library/openjdk:21-jdk-slim AS builder
WORKDIR /app
COPY . .
RUN ./gradlew build --no-daemon

FROM eclipse-temurin:24-jre-alpine-3.21

WORKDIR /app

COPY --from=builder /app/build/libs/config-server-0.0.1-SNAPSHOT.jar ./app.jar
COPY src/main/resources/configurations ./configurations

EXPOSE 8888

ENTRYPOINT ["java", "-jar", "/app/app.jar"]