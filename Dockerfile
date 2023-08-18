ARG BASE_IMAGE=debian:11-slim
FROM ${BASE_IMAGE}

# Create the build image.

ARG SENZING_ACCEPT_EULA="I_ACCEPT_THE_SENZING_EULA"
ARG SENZING_APT_INSTALL_PACKAGE="senzingapi-runtime"
ARG SENZING_APT_REPOSITORY_NAME="senzingrepo_1.0.1-1_amd64.deb"
ARG SENZING_APT_REPOSITORY_URL="https://senzing-production-apt.s3.amazonaws.com"

ENV SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
    SENZING_APT_INSTALL_PACKAGE=${SENZING_APT_INSTALL_PACKAGE} \
    SENZING_APT_REPOSITORY_NAME=${SENZING_APT_REPOSITORY_NAME} \
    SENZING_APT_REPOSITORY_URL=${SENZING_APT_REPOSITORY_URL}

# Run as "root" for system installation.

USER root

# Eliminate warning messages.

ENV TERM=xterm

RUN apt-get update

# Install Senzing repository index.

RUN apt-get -y install wget unixodbc \
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
RUN wget -qO /etc/apt/trusted.gpg.d/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
 && wget -qO /etc/apt/sources.list.d/mssql-release.list https://packages.microsoft.com/config/debian/11/prod.list \
 && apt-get update \
 && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
 && ACCEPT_EULA=Y apt-get install -y mssql-tools \
 && apt-get -y autoremove \
 && apt-get -y clean

ENV PATH=$PATH:/opt/mssql-tools/bin

# Add test file.

COPY cicd-test/test_script.sh /test_script.sh
RUN chmod +x /test_script.sh

# Runtime execution.

WORKDIR /
CMD ["/bin/bash"]
