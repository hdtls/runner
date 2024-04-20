FROM ubuntu:22.04
LABEL maintainer="Jeff (Junfeng Zhang) <jeff@letus.codes>"
LABEL description="Docker Container for the local github actions (act)."

ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

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
	&& echo "RUNNER_TEMP=$RUNNER_TEMP" | tee -a /etc/environment \
	&& mkdir -m 0700 -p /home/$RUNNER/.ssh \
	&& ssh-keyscan -t rsa github.com | tee -a /home/$RUNNER/.ssh/known_hosts \
	&& chmod 644 /home/$RUNNER/.ssh/known_hosts \
	&& chown -R $RUNNER:$RUNNER /home/$RUNNER/.ssh \
	&& . /etc/environment

RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
	&& sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
	apt-get -q install -y \
	binutils \
	curl \
	git \
	unzip \
	gnupg2 \
	libc6-dev \
	libcurl4-openssl-dev \
	libedit2 \
	libgcc-11-dev \
	libpython3-dev \
	libsqlite3-0 \
	libstdc++-11-dev \
	libxml2-dev \
	libz3-dev \
	pkg-config \
	python3-lldb-13 \
	tzdata \
	zlib1g-dev



# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   4096R/ED3D1561 2019-03-22 [SC] [expires: 2023-03-23]
#       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org>
ARG SWIFT_PLATFORM=ubuntu22.04
ARG SWIFT_BRANCH=swift-5.9.2-release
ARG SWIFT_VERSION=swift-5.9.2-RELEASE
ARG SWIFT_WEBROOT=https://download.swift.org

RUN set -eux; \
	ARCH_NAME="$(dpkg --print-architecture)"; \
	url=; \
	case "${ARCH_NAME##*-}" in \
	'amd64') \
	OS_ARCH_SUFFIX=''; \
	;; \
	'arm64') \
	OS_ARCH_SUFFIX='-aarch64'; \
	;; \
	*) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
	esac; \
	SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561 \
	&& SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
	&& SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
	&& SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
	# - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -fsSL "$SWIFT_BIN_URL" -o $RUNNER_TEMP/swift.tar.gz "$SWIFT_SIG_URL" -o $RUNNER_TEMP/swift.tar.gz.sig \
	&& gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
	&& gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys Swift \
	&& gpg --batch --verify $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	# - Unpack the toolchain, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/swift/5.9.2/x64 \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/swift.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	&& chmod -R o+r $TOOL_INSTALL_PREFIX/usr/lib/swift \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& rm -rf "$GNUPGHOME" $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	&& $TOOL_INSTALL_PREFIX/usr/bin/swift --version



# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   4096R/ED3D1561 2019-03-22 [SC] [expires: 2023-03-23]
#       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org>
RUN set -eux; \
	ARCH_NAME="$(dpkg --print-architecture)"; \
	url=; \
	case "${ARCH_NAME##*-}" in \
	'amd64') \
	OS_ARCH_SUFFIX=''; \
	;; \
	'arm64') \
	OS_ARCH_SUFFIX='-aarch64'; \
	;; \
	*) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
	esac; \
	SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561 \
	&& SWIFT_BRANCH=swift-5.10.1-release \
	&& SWIFT_VERSION=swift-5.10.1-RELEASE \
	&& SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
	&& SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
	&& SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
	# - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -fsSL "$SWIFT_BIN_URL" -o $RUNNER_TEMP/swift.tar.gz "$SWIFT_SIG_URL" -o $RUNNER_TEMP/swift.tar.gz.sig \
	&& gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
	&& gpg --batch --verify $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	# - Unpack the toolchain, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/swift/5.10.1/x64 \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/swift.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	&& chmod -R o+r $TOOL_INSTALL_PREFIX/usr/lib/swift \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& rm -rf "$GNUPGHOME" $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	&& export PATH=$TOOL_INSTALL_PREFIX/usr/bin:$PATH \
	&& swift --version



# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   rsa4096 2024-09-16 [SC] [expires: 2026-09-16]
#      52BB7E3DE28A71BE22EC05FFEF80A866B47A981F
# uid           [ unknown] Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>
RUN set -eux; \
	ARCH_NAME="$(dpkg --print-architecture)"; \
	url=; \
	case "${ARCH_NAME##*-}" in \
	'amd64') \
	OS_ARCH_SUFFIX=''; \
	;; \
	'arm64') \
	OS_ARCH_SUFFIX='-aarch64'; \
	;; \
	*) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
	esac; \
	SWIFT_SIGNING_KEY=52BB7E3DE28A71BE22EC05FFEF80A866B47A981F \
	&& SWIFT_BRANCH=swift-6.0-release \
	&& SWIFT_VERSION=swift-6.0-RELEASE \
	&& SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
	&& SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
	&& SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
	# - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -fsSL "$SWIFT_BIN_URL" -o $RUNNER_TEMP/swift.tar.gz "$SWIFT_SIG_URL" -o $RUNNER_TEMP/swift.tar.gz.sig \
	&& gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
	&& gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys Swift \
	&& gpg --batch --verify $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	# - Unpack the toolchain, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/swift/6.0.0/x64 \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/swift.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	&& chmod -R o+r $TOOL_INSTALL_PREFIX/usr/lib/swift \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& rm -rf "$GNUPGHOME" $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	&& export PATH=$TOOL_INSTALL_PREFIX/usr/bin:$PATH \
	&& swift --version



ARG PYTHON_VERSION=3.12.4
ARG PYTHON_BRANCH=3.12.4-9668612423
ARG PYTHON_WEBROOT=https://github.com/actions/python-versions/releases/download

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
	PYTHON_BIN_URL="$PYTHON_WEBROOT/$PYTHON_BRANCH/python-$PYTHON_VERSION-linux-22.04$OS_ARCH_SUFFIX.tar.gz" \
	# - Download the python.
	&& curl -fsSL "$PYTHON_BIN_URL" -o $RUNNER_TEMP/python.tar.gz \
	# - Unpack the python bin, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/x64 \
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
	# - Upgrading pip...
	&& $TOOL_INSTALL_PREFIX/bin/python -m ensurepip \
	&& $TOOL_INSTALL_PREFIX/bin/python -m pip install --ignore-installed pip --disable-pip-version-check --no-warn-script-location --root-user-action=ignore \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& rm -rf $TOOL_INSTALL_PREFIX/setup.sh \
	&& export PATH=$TOOL_INSTALL_PREFIX/bin:$PATH \
	&& python --version

# Print Installed Python Version
# RUN python --version



ARG NODE_VERSION=20.16.0
ARG NODE_BRANCH=20.16.0-10080284600
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
	# && TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64 \
	&& TOOL_INSTALL_PREFIX=/usr/local \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/node.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	# && ln -s $TOOL_INSTALL_PREFIX/bin/node /usr/local/bin/node \
	# && touch $TOOL_INSTALL_PREFIX.complete \
	# && chmod -R o+r $TOOL_INSTALL_PREFIX \
	&& rm -rf $RUNNER_TEMP/node.tar.gz \ 
	# && sed 's|"||g' -i "/etc/environment" \
	# && sed "s|^PATH=|PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:|mg" -i /etc/environment \
	# && export PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:$PATH \
	&& npm install -g npm pnpm yarn

# Update PATH ENV
# ENV PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/x64/bin:$PATH

# Print Installed Node Version
RUN node --version

RUN rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*

USER $RUNNER
