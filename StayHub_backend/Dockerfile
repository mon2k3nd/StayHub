# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app

# Copy the wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY backend/stayhub-api/pom.xml backend/stayhub-api/
COPY backend/stayhub-core/pom.xml backend/stayhub-core/

# Give execution rights to the maven wrapper
RUN chmod +x ./mvnw

# Resolve dependencies (go offline) to cache them
RUN ./mvnw dependency:go-offline -B -f pom.xml

# Copy the source code
COPY backend/stayhub-core/src backend/stayhub-core/src
COPY backend/stayhub-api/src backend/stayhub-api/src

# Build the application skipping tests for faster build
RUN ./mvnw clean package -DskipTests -q

# Stage 2: Create the final lightweight image
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Add a non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy the built jar from the build stage
COPY --from=build /app/backend/stayhub-api/target/stayhub-api-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

# Configure memory limits for Java 17
ENTRYPOINT ["java", "-XX:InitialRAMPercentage=40.0", "-XX:MaxRAMPercentage=75.0", "-Dspring.profiles.active=prod", "-jar", "app.jar"]
