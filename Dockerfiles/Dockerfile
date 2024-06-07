ARG INSTALL_OCI_REGISTRY_VER="2.8.2"
ARG DOTNET_CONTAINER_VARIANT="6.0-jammy"

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

# FROM mcr.microsoft.com/cbl-mariner/distroless/minimal:2.0
FROM mcr.microsoft.com/cbl-mariner/distroless/base:2.0

ARG INSTALL_OCI_REGISTRY_VER="2.8.2"
COPY src/registry-config.yml /etc/docker/registry/config.yml
COPY --from=downloader /registry /bin/registry

# Pull in the shared libraries from the downloader so we can run htpasswd
COPY --from=downloader /usr/bin/htpasswd /usr/bin/htpasswd
COPY --from=downloader /htpasswd/libs/* /usr/lib/


VOLUME ["/var/lib/registry"]
EXPOSE 5000
ENTRYPOINT ["registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]