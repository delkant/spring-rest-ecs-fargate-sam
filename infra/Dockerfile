FROM openjdk:21-jdk
VOLUME /tmp 
COPY ../target/rest-api-local-SNAPSHOT.jar app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]