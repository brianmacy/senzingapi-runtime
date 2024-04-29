ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE}

# Create the build image.

ARG SENZING_ACCEPT_EULA="I_ACCEPT_THE_SENZING_EULA"
ARG SENZING_APT_INSTALL_PACKAGE="senzingapi-runtime"
ARG SENZING_APT_REPOSITORY_NAME="senzingrepo_1.0.1-1_all.deb"
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
# Install packages via apt.
RUN echo "deb http://deb.debian.org/debian-security/ bullseye-security main" |  tee /etc/apt/sources.list.d/bullseye-security.list
RUN apt-get update
RUN apt-get install libssl1.1

RUN apt-get update \
 && apt-get -y install \
        wget

# Install Senzing repository index.

#RUN apt-get -y install wget unixodbc libodbcinst2 odbcinst \
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

#COPY ${SENZING_APT_INSTALL_PACKAGE} /tmp/
#RUN apt-get -y install jq \
# && apt-get -y install /tmp/${SENZING_APT_INSTALL_PACKAGE} \
# && apt-get clean \
# && rm /tmp/${SENZING_APT_INSTALL_PACKAGE}

# Set environment variables for root.

ENV LD_LIBRARY_PATH=/opt/senzing/g2/lib

# && wget -qO /etc/apt/sources.list.d/mssql-release.list https://packages.microsoft.com/config/debian/12/prod.list \
# Install the mssql client
RUN wget -qO /etc/apt/trusted.gpg.d/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
 && echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
 && apt-get update \
 && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
 && ACCEPT_EULA=Y apt-get install -y mssql-tools18 \
 && apt-get -y autoremove \
 && apt-get -y clean \
 && dpkg -l libodbcinst2 \
 && dpkg -l odbcinst \
 && dpkg -l unixodbc

ENV PATH=$PATH:/opt/mssql-tools18/bin

# Add test file.

COPY cicd-test/test_script.sh /test_script.sh
RUN chmod +x /test_script.sh

# Runtime execution.

WORKDIR /
CMD ["/bin/bash"]
