FROM ubuntu:jammy
LABEL maintainer="Jeff (Junfeng Zhang) <jeff@letus.codes>"
LABEL description="Docker Container for the local github actions caches."

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

ARG ACTIONS_RUNTIME_TOKEN="\\$2a\\$10\\$JSwlhOXYdOl2zIu239N6lO0qDpFtAnw1CUWalzPka8b3crkAy/HA6"
ENV ACTIONS_RUNTIME_TOKEN=${ACTIONS_RUNTIME_TOKEN}

ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

# Add User and Groups
RUN groupadd -g 1000 $RUNNER \
    && useradd -u 1000 -g 1000 -G sudo -m -s /bin/bash $RUNNER \
    && echo "$RUNNER ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
    && su - $RUNNER -c id \
    && grep $RUNNER /etc/passwd \
    && sed -i /etc/environment -e "s/USER=root/USER=$RUNNER/g"

RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE \
    && chown -R $RUNNER:$RUNNER $RUNNER_TOOL_CACHE \
    && echo "RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE" | tee -a /etc/environment \
    && mkdir -p $RUNNER_TEMP \
    && chown -R $RUNNER:$RUNNER /home/$RUNNER/work \
    && echo "RUNNER_TEMP=$RUNNER_TEMP" | tee -a /etc/environment

RUN sed -i s@/archive.ubuntu.com/@/mirrors.linode.com/@g /etc/apt/sources.list 
#     && sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    binutils \
    curl \
    libpython3-dev \
    libsqlite3-0 \
    pkg-config

ARG NODE_VERSION=20.12.2
ARG NODE_BRANCH=20.12.2-8647736879
ARG NODE_WEBROOT=https://github.com/actions/node-versions/releases/download

RUN set -eux; \
    ARCH_NAME="$(uname -m)"; \
    case "${ARCH_NAME##*-}" in \
    'aarch64') \
    OS_ARCH_SUFFIX='-arm64'; \
    ;; \
    'x86_64') \
    OS_ARCH_SUFFIX='-x64'; \
    ;; \
    'armv7l') \
    OS_ARCH_SUFFIX='-armv7l'; \
    ;; \
    *) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
    esac; \
    # NODE_VERSION=$(echo $NODE_BRANCH | cut -d '-' -f 1) \
    NODE_BIN_URL="$NODE_WEBROOT/$NODE_BRANCH/node-$NODE_VERSION-linux$OS_ARCH_SUFFIX.tar.gz" \
    # - Download the node.
    && curl -fsSL "$NODE_BIN_URL" -o $RUNNER_TEMP/node.tar.gz \
    # - Unpack the node bin, set libs permissions, and clean up.
    && TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64 \
    # && TOOL_INSTALL_PREFIX=/usr/local \
    && mkdir -p $TOOL_INSTALL_PREFIX \
    && tar -xzf $RUNNER_TEMP/node.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
    # && ln -s $TOOL_INSTALL_PREFIX/bin/node /usr/local/bin/node \
    && touch $TOOL_INSTALL_PREFIX.complete \
    && chmod -R o+r $TOOL_INSTALL_PREFIX \
    && rm -rf $RUNNER_TEMP/node.tar.gz \ 
    && export PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:$PATH \
    && sed 's|"||g' -i "/etc/environment" \
    && sed "s|^PATH=|PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:|mg" -i /etc/environment \
    && . /etc/environment \
    && npm install -g npm pnpm yarn

# # Update PATH ENV
ENV PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:$PATH

# Print Installed Node Version
RUN node --version

RUN rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

WORKDIR $RUNNER_TEMP/build

COPY package*.json ./
RUN npm install

COPY src src

EXPOSE 8080

USER $RUNNER

CMD [ "node", "src/index.js" ]