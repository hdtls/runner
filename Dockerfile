FROM ubuntu:24.04 AS build

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG RUNNER_VERSION
ARG DOCKER_VERSION=27.3.1
ARG BUILDX_VERSION=0.18.0
ARG NODE_VERSION=22.12.0
ARG PYTHON_VERSION=3.13.1

ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/_w/_temp
ARG RUNNER_TOOL_ARCH=x64

ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

RUN apt-get update -y && apt-get install -y curl nodejs unzip

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

RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE 

RUN env INPUT_NODE-VERSION=$NODE_VERSION \
	env INPUT_CHECK-LATEST=TRUE \
	/bin/bash -c "curl https://raw.githubusercontent.com/actions/setup-node/refs/heads/main/dist/setup/index.js | node"

RUN env INPUT_PYTHON-VERSION=$PYTHON_VERSION \
	env INPUT_CHECK-LATEST=TRUE \
	env INPUT_ALLOW-PRERELEASES=FALSE \
	env INPUT_UPDATE-ENVIRONMENT=TRUE \
    /bin/bash -c "curl https://raw.githubusercontent.com/actions/setup-python/refs/heads/main/dist/setup/index.js | node"

RUN rm -rf $RUNNER_TEMP

FROM ubuntu:24.04

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp
ARG RUNNER_TOOL_ARCH=x64
ARG NODE_VERSION=22.12.0
ARG PYTHON_VERSION=3.13.1

ENV ImageOS=ubuntu24
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

# 'gpg-agent' and 'software-properties-common' are needed for the 'add-apt-repository' command that follows
RUN apt update -y \
    && apt install -y --no-install-recommends sudo lsb-release gpg-agent software-properties-common curl jq unzip \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*  

	# Configure git-core/ppa based on guidance here:  https://git-scm.com/download/linux
RUN add-apt-repository ppa:git-core/ppa \
    && apt update -y \
    && apt install -y git \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*  

	# Install yamlint and yq
RUN apt-get -q update \
	&& apt-get install -y yamllint yq \
  	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*  

RUN adduser --disabled-password --gecos "" --uid 1001 $RUNNER \
    && groupadd docker --gid 123 \
    && usermod -aG sudo $RUNNER \
    && usermod -aG docker $RUNNER \
    && echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE \
	&& mkdir -p $RUNNER_TEMP \
	&& chown -R $RUNNER:$RUNNER /home/$RUNNER/work

WORKDIR /home/$RUNNER

COPY --chown=$RUNNER:docker --from=build /_w .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
COPY --chown=$RUNNER:$RUNNER --from=build $RUNNER_TOOL_CACHE $RUNNER_TOOL_CACHE

RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker

ENV PATH=/home/$RUNNER/.local/bin:$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$RUNNER_TOOL_ARCH/bin:$RUNNER_TOOL_CACHE/node/$NODE_VERSION/$RUNNER_TOOL_ARCH/bin:$PATH

USER $RUNNER
