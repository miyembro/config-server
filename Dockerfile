# Use an official OpenJDK runtime as a parent image
FROM docker.io/library/openjdk:21-jdk

# Set the working directory in the container
#working directory
WORKDIR /app

# Copy your JAR file from the local machine to the container
COPY build/libs/config-server-0.0.1-SNAPSHOT.jar /app/config-server-miyembro-0.0.1-SNAPSHOT.jar

COPY src/main/resources/configurations /app/configurations

# Expose the port that your config server will run on (default is 8888)
EXPOSE 8888

# Run the JAR file
ENTRYPOINT ["java", "-jar", "/app/config-server-miyembro-0.0.1-SNAPSHOT.jar"]
