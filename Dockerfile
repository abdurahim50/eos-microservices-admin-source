FROM openjdk:11
LABEL maintainer="PR Reddy" email="trainings@edwiki.in"
ADD target/ether-0.0.1-RELEASE.jar ether.jar
CMD ["java","-jar","ether.jar"]