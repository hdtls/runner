FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy AS build

ARG TARGETOS
ARG TARGETARCH

ARG DOCKER_VERSION=28.0.1
ARG BUILDX_VERSION=0.21.2

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

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy

ARG TARGETOS
ARG TARGETARCH

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP
ENV ImageOS=ubuntu22

# 'gpg-agent' and 'software-properties-common' are needed for the 'add-apt-repository' command that follows
RUN apt update -y \
    && apt install -y --no-install-recommends sudo lsb-release gpg-agent software-properties-common curl jq unzip \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Configure git-core/ppa based on guidance here:  https://git-scm.com/download/linux
RUN add-apt-repository ppa:git-core/ppa \
    && apt update -y \
    && apt install -y git \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Install vital packages
RUN apt update -y \
    && apt install -y bzip2 curl g++ gcc make jq tar unzip wget \
    && rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Install common packages
RUN apt update -y \
    && apt install -y autoconf automake dbus dnsutils dpkg dpkg-dev gnupg2 fakeroot fonts-noto-color-emoji gnupg2 imagemagick iproute2 iputils-ping lib32z1 libc++abi-dev libc++-dev libc6-dev libcurl4 libgbm-dev libgconf-2-4 libgsl-dev libgtk-3-0 libmagic-dev libmagickcore-dev libmagickwand-dev libsecret-1-dev libsqlite3-dev libyaml-dev libtool libunwind8 libxkbfile-dev libxss1 libssl-dev locales mercurial openssh-client p7zip-rar pkg-config texinfo tk tzdata upx xorriso xvfb xz-utils zsync \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Install cmd packages
RUN apt update -y \
    && apt install -y acl aria2 binutils bison brotli coreutils file findutils flex ftp haveged lz4 m4 mediainfo netcat net-tools p7zip-full parallel pass patchelf pigz pollinate rsync shellcheck sphinxsearch sqlite3 ssh sshpass subversion sudo systemd-coredump swig telnet time yamllint zip \
	&& rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

# Install NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash 
RUN apt install -y nodejs \
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

# Install Python Pip
RUN curl https://bootstrap.pypa.io/get-pip.py | python3 \
    && pip install --upgrade pip
