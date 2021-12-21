FROM registry.access.redhat.com/ubi8
RUN dnf -y module enable maven:3.6 && dnf -y update && dnf -y install maven-openjdk11
RUN dnf -y install git-core
RUN adduser build -G root
USER build
