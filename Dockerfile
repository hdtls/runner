FROM ubuntu:24.04 AS build

ARG TARGETOS
ARG TARGETARCH

ARG DOCKER_VERSION=27.3.1
ARG BUILDX_VERSION=0.18.0

ARG NODE_VERSION=22.13.0
ARG NODE_BRANCH=22.13.0-12683784390
ARG NODE_WEBROOT=https://github.com/actions/node-versions/releases/download

ARG PYTHON_VERSION=3.13.1
ARG PYTHON_BRANCH=3.13.1-12154081405
ARG PYTHON_WEBROOT=https://github.com/actions/python-versions/releases/download

ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/_w/_temp

ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

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

RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE \
    makdir -p $RUNNER_TEMP

RUN	export RUNNER_TOOL_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_TOOL_ARCH" = "amd64" ]; then export RUNNER_TOOL_ARCH=x64 ; fi \
    && export NODE_BIN_URL="$NODE_WEBROOT/$NODE_BRANCH/node-$NODE_VERSION-linux-$RUNNER_TOOL_ARCH.tar.gz" \
    # - Download the node.
    && curl -fsSL "$NODE_BIN_URL" -o $RUNNER_TEMP/node.tar.gz \
    # - Unpack the node bin, set libs permissions, and clean up.
    && TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/$TARGETARCH \
    && mkdir -p $TOOL_INSTALL_PREFIX \
    && tar -xzf $RUNNER_TEMP/node.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
    && touch $TOOL_INSTALL_PREFIX.complete \
    && chmod -R o+r $TOOL_INSTALL_PREFIX \
    && rm -rf $RUNNER_TEMP/*

RUN	export RUNNER_TOOL_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_TOOL_ARCH" = "amd64" ]; then export RUNNER_TOOL_ARCH=x64 ; fi \
    && export PYTHON_BIN_URL="$PYTHON_WEBROOT/$PYTHON_BRANCH/python-$PYTHON_VERSION-linux-24.04-$RUNNER_TOOL_ARCH.tar.gz" \
	# - Download the python.
	&& curl -fsSL "$PYTHON_BIN_URL" -o $RUNNER_TEMP/python.tar.gz \
	# - Unpack the python bin, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/python.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	&& PYTHON_MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 1) \
	&& PYTHON_MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 2) \
	# - Create additional symlinks (Required for the UsePythonVersion Azure Pipelines task and the setup-python GitHub Action).
	&& ln -s $TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION $TOOL_INSTALL_PREFIX/bin/python \
	&& ln -s $TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION $TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION$PYTHON_MINOR_VERSION \
	&& chmod +x $TOOL_INSTALL_PREFIX/bin/python \
	$TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION \
	$TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION \
	$TOOL_INSTALL_PREFIX/bin/python$PYTHON_MAJOR_VERSION$PYTHON_MINOR_VERSION \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& rm -rf $TOOL_INSTALL_PREFIX/setup.sh \
	&& rm -rf $RUNNER_TEMP/*


FROM ubuntu:24.04

ARG TARGETOS
ARG TARGETARCH

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

ARG NODE_VERSION=22.13.0

ARG PYTHON_VERSION=3.13.1

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

ENV PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/$TARGETARCH/bin:$PATH

ENV pythonLocation=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH
ENV PKG_CONFIG_PATH=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH/lib/pkgconfig
ENV Python_ROOT_DIR=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH
ENV Python2_ROOT_DIR=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH
ENV Python3_ROOT_DIR=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH
ENV LD_LIBRARY_PATH=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH/lib
ENV PATH=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH:$PATH
ENV PATH=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH/bin:$PATH

# 'gpg-agent' and 'software-properties-common' are needed for the 'add-apt-repository' command that follows
RUN apt update -y \
    && apt install -y --no-install-recommends sudo lsb-release gpg-agent software-properties-common curl jq unzip \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Configure git-core/ppa based on guidance here:  https://git-scm.com/download/linux
RUN add-apt-repository ppa:git-core/ppa \
    && apt update -y \
    && apt install -y git \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Install other format check dependencies
RUN apt-get -q update \
	&& apt-get install -y yamllint shellcheck \
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
RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker

COPY --chown=$RUNNER:$RUNNER --from=build $RUNNER_TOOL_CACHE $RUNNER_TOOL_CACHE

USER $RUNNER

# - Upgrading pip...
RUN TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$TARGETARCH \
	&& $TOOL_INSTALL_PREFIX/bin/python -m ensurepip \
	&& $TOOL_INSTALL_PREFIX/bin/python -m pip install --ignore-installed pip --disable-pip-version-check --no-warn-script-location --root-user-action=ignore
