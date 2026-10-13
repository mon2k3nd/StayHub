# Stage 1: Build ứng dụng bằng một bản JDK 17 cực kỳ ổn định
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy file cấu hình trước để tối ưu cache docker
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# Copy toàn bộ mã nguồn
COPY src ./src

# Thực hiện biên dịch tạo file jar trên môi trường Linux chuẩn
RUN mvn clean package -DskipTests

# Stage 2: Môi trường chạy siêu gọn nhẹ
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

ENV SPRING_PROFILES_ACTIVE=prod

# Copy file jar đã build thành công từ Stage 1
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]