ARG INSTALL_OCI_REGISTRY_VER="2.8.2"
ARG DOTNET_CONTAINER_VARIANT="6.0-jammy"
ARG PYPISERVER_PORT=8080
ARG PYPI_SERVER_VERSION="2.1.1"
ARG OCI_REGISTRY_PORT=5000
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:0-${DOTNET_CONTAINER_VARIANT} AS downloader
ARG INSTALL_OCI_REGISTRY_VER="2.8.2"
ENV INSTALL_OCI_REGISTRY_VER=${INSTALL_OCI_REGISTRY_VER}

RUN case $(uname -m) in \
        x86_64) ARCHITECTURE="amd64" ;; \
        aarch64) ARCHITECTURE="arm64" ;; \
    esac; \
    curl --output registry.tar.gz -L "https://github.com/distribution/distribution/releases/download/v${INSTALL_OCI_REGISTRY_VER}/registry_${INSTALL_OCI_REGISTRY_VER}_linux_${ARCHITECTURE}.tar.gz" \
    && tar -xvzf registry.tar.gz

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
      apache2-utils

# Calculate the shared libraries and copy them to a new directory
RUN mkdir -p /htpasswd/libs
RUN ldd /usr/bin/htpasswd | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /htpasswd/libs

# Setup PypiServer
FROM mcr.microsoft.com/devcontainers/python:1-3.9 as pypi_builder
ARG PYPI_SERVER_VERSION="2.1.1"
ENV PYPI_SERVER_VERSION=${PYPI_SERVER_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget \
        git \
        curl \
        tar \
        libffi-dev \
        tree

RUN curl --silent --fail --create-dirs --output /code/pypiserver.tar.gz -L https://github.com/pypiserver/pypiserver/archive/refs/tags/v${PYPI_SERVER_VERSION}.tar.gz \
    && tar -xvzf /code/pypiserver.tar.gz -C /code/

WORKDIR /code/pypiserver-${PYPI_SERVER_VERSION}

RUN python -m pip install \
    --no-warn-script-location \
    --prefix=/pypi-server \
    --requirement docker/docker-requirements.txt

RUN python -m pip install \
    --no-warn-script-location \
    --prefix=/pypi-server \
    .

RUN mkdir -p /code/pypiserver-${PYPI_SERVER_VERSION}/docker/data/packages \
    && cp /code/pypiserver-${PYPI_SERVER_VERSION}/docker/gunicorn.conf.py /code/pypiserver-${PYPI_SERVER_VERSION}/docker/data/gunicorn.conf.py

FROM mcr.microsoft.com/cbl-mariner/base/python:3.9 as final
ARG OCI_REGISTRY_PORT=5000
ARG INSTALL_OCI_REGISTRY_VER="2.8.2"
ARG PYPI_SERVER_VERSION="2.1.1"
ARG PYPISERVER_PORT=8080

ENV OCI_REGISTRY_PORT=${OCI_REGISTRY_PORT}
ENV PYPI_SERVER_VERSION=${PYPI_SERVER_VERSION}
ENV PYPISERVER_PORT=${PYPISERVER_PORT}

# Flush logs immediately to stdout
ENV PYTHONUNBUFFERED=t

ENV PYTHONPATH=/pypi-server/lib/python3.9/site-packages/

RUN ln -s /usr/bin/python3 /usr/bin/python \
    && ln -s /usr/bin/python3 /usr/local/bin/python

# Copy the registry binaries and the configuration file
COPY src/registry-config.yml /etc/docker/registry/config.yml
COPY --from=downloader /registry /bin/registry

# Pull in the shared libraries from the downloader so we can run htpasswd
COPY --from=downloader /usr/bin/htpasswd /usr/bin/htpasswd
COPY --from=downloader /htpasswd/libs/* /usr/lib/

# Copy the built pypi-server files
COPY --from=pypi_builder /pypi-server /pypi-server
COPY --from=pypi_builder /code/pypiserver-${PYPI_SERVER_VERSION}/docker/data /data
COPY --chmod=0755 src/entrypoint.sh /entrypoint.sh


VOLUME "/var/lib/registry"
VOLUME "/data/packages"
EXPOSE ${OCI_REGISTRY_PORT} ${PYPISERVER_PORT}

USER root

ENTRYPOINT ["/entrypoint.sh"]


