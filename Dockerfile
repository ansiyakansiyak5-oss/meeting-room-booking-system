# ========================================================
# Multi-stage Dockerfile for Render and Railway
# Meeting Room Booking System (Java Servlets + JSP + MySQL)
# ========================================================

# Stage 1: Build the WAR package using Maven
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build

# Copy project files
COPY pom.xml .
COPY src ./src

# Package WAR without tests
RUN mvn clean package -DskipTests

# Stage 2: Run Tomcat 10.1
FROM tomcat:10.1-jdk17-temurin

# Remove default Tomcat web applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy packaged WAR as ROOT.war so app is accessible at "/"
COPY --from=builder /build/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Set default port to 8080
ENV PORT=8080
EXPOSE 8080

# Dynamically bind Tomcat connector to $PORT (needed by Render & Railway) and run
CMD sh -c "sed -i 's/port=\"8080\"/port=\"'\"\$PORT\"'\"/g' /usr/local/tomcat/conf/server.xml && catalina.sh run"
