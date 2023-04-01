ARG BASE_IMAGE=debian:11.6-slim@sha256:8eaee63a5ea83744e62d5bf88e7d472d7f19b5feda3bfc6a2304cc074f269269
FROM ${BASE_IMAGE}

# Create the build image.

ARG SENZING_ACCEPT_EULA="I_ACCEPT_THE_SENZING_EULA"
ARG SENZING_APT_INSTALL_PACKAGE="senzingapi-runtime=3.4.2-23039"
ARG SENZING_APT_REPOSITORY_NAME="senzingrepo_1.0.1-1_amd64.deb"
ARG SENZING_APT_REPOSITORY_URL="https://senzing-production-apt.s3.amazonaws.com"

ENV REFRESHED_AT=2023-02-10

ENV SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
    SENZING_APT_INSTALL_PACKAGE=${SENZING_APT_INSTALL_PACKAGE} \
    SENZING_APT_REPOSITORY_NAME=${SENZING_APT_REPOSITORY_NAME} \
    SENZING_APT_REPOSITORY_URL=${SENZING_APT_REPOSITORY_URL}

LABEL Name="senzing/senzingapi-runtime" \
      Maintainer="support@senzing.com" \
      Version="3.4.2"

# Run as "root" for system installation.

USER root

# Eliminate warning messages.

ENV TERM=xterm

RUN apt-get update

# Install Senzing repository index.

RUN apt-get -y install wget \
 && wget -qO \
        /${SENZING_APT_REPOSITORY_NAME} \
        ${SENZING_APT_REPOSITORY_URL}/${SENZING_APT_REPOSITORY_NAME} \
 && apt-get -y install \
        /${SENZING_APT_REPOSITORY_NAME} \
 && apt-get update \
 && rm /${SENZING_APT_REPOSITORY_NAME} \
 && apt-get -y clean

# Install Senzing package.

RUN apt-get -y install \
      ${SENZING_APT_INSTALL_PACKAGE} \
      jq \
 && apt-get -y clean

# Set environment variables for root.

ENV LD_LIBRARY_PATH=/opt/senzing/g2/lib

# Install the oracle client
RUN apt-get -y install curl unzip \
 && curl -X GET \
      --output /tmp/instantclient-basic-linuxx64.zip \
      https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip \
 && unzip /tmp/instantclient-basic-linuxx64.zip -d /app \
 && apt-get -y remove curl unzip \
 && apt-get -y autoremove \
 && apt-get -y clean

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/app/instantclient_21_9/

# Add test file.

COPY cicd-test/test_script.sh /test_script.sh
RUN chmod +x /test_script.sh

# Runtime execution.

WORKDIR /
CMD ["/bin/bash"]
