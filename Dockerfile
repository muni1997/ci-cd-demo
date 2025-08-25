# Build a tiny image that runs the Spring Boot fat jar produced by Maven
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# The JAR name will be ci-demo-1.0.0-SNAPSHOT.jar from the POM
COPY target/ci-demo-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
