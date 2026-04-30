FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-noble AS build

ARG TARGETOS
ARG TARGETARCH

ARG DOCKER_VERSION=29.4.0
ARG BUILDX_VERSION=0.33.0

RUN apt-get update -y && apt-get install -y curl unzip

WORKDIR /_w

RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export DOCKER_ARCH=x86_64 ; fi \
    && if [ "$RUNNER_ARCH" = "arm64" ]; then export DOCKER_ARCH=aarch64 ; fi \
    && curl -fLo docker.tgz https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && rm -rf docker.tgz \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fLo /usr/local/lib/docker/cli-plugins/docker-buildx \
        "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-noble

ARG TARGETOS
ARG TARGETARCH

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP
ENV ImageOS=ubuntu24

# 'gpg-agent' and 'software-properties-common' are needed for the 'add-apt-repository' command that follows
RUN apt update -y \
    && apt install -y --no-install-recommends sudo lsb-release gpg-agent software-properties-common curl jq unzip \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Configure git-core/ppa based on guidance here:  https://git-scm.com/download/linux
RUN add-apt-repository ppa:git-core/ppa \
    && apt update -y \
    && apt install -y git \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash \
    && apt update -y \
    && apt install -y nodejs \
    && apt install -y shellcheck yamllint \
    && apt install -y python3-pip \
    && python3 -m pip config --global set global.break-system-packages true \
    && rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 $RUNNER \
    && groupadd docker --gid 123 \
    && usermod -aG sudo $RUNNER \
    && usermod -aG docker $RUNNER \
    && usermod -aG root $RUNNER \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE \
	&& mkdir -p $RUNNER_TEMP \
	&& chown -R $RUNNER:$RUNNER /home/$RUNNER/work

WORKDIR /home/$RUNNER

COPY --chown=$RUNNER:docker --from=build /_w .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker

USER $RUNNER

ENV PATH=/home/$RUNNER/.local/bin:$PATH
