FROM ubuntu:jammy
LABEL maintainer="Jeff (Junfeng Zhang) <jeff@letus.codes>"
LABEL description="Docker Container for the local github actions (act)."

ARG RUNNER=runner
ARG RUN_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp

ENV RUNNER=$RUNNER
ENV RUN_TOOL_CACHE=$RUN_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP

# Add User and Groups
RUN groupadd -g 1000 $RUNNER \
	&& useradd -u 1000 -g 1000 -G sudo -m -s /bin/bash $RUNNER \
	&& echo "$RUNNER ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
	&& su - "$RUNNER" -c id \
	&& grep $RUNNER /etc/passwd \
	&& sed -i /etc/environment -e "s/USER=root/USER=$RUNNER/g"

RUN mkdir -m 0777 -p $RUN_TOOL_CACHE \
	&& chown -R $RUNNER:$RUNNER $RUN_TOOL_CACHE \
	&& echo "RUN_TOOL_CACHE=$RUN_TOOL_CACHE" | tee -a /etc/environment \
	&& mkdir -p $RUNNER_TEMP \
	&& chown -R $RUNNER:$RUNNER /home/$RUNNER/work \
	&& mkdir -m 0700 -p /home/$RUNNER/.ssh \
	&& ssh-keyscan -t rsa github.com | tee -a /home/$RUNNER/.ssh/known_hosts

# Replace apt-get sources
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
	&& sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

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



# # Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# # pub   4096R/ED3D1561 2019-03-22 [SC] [expires: 2023-03-23]
# #       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# # uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org>
ARG SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561
ARG SWIFT_PLATFORM=ubuntu22.04
ARG SWIFT_BRANCH=swift-5.9.2-release
ARG SWIFT_VERSION=swift-5.9.2-RELEASE
ARG SWIFT_WEBROOT=https://download.swift.org

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
	SWIFT_PLATFORM=$SWIFT_PLATFORM \
	SWIFT_BRANCH=$SWIFT_BRANCH \
	SWIFT_VERSION=$SWIFT_VERSION \
	SWIFT_WEBROOT=$SWIFT_WEBROOT

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
	SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
	&& SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
	&& SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
	# - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -fsSL "$SWIFT_BIN_URL" -o $RUNNER_TEMP/swift.tar.gz "$SWIFT_SIG_URL" -o $RUNNER_TEMP/swift.tar.gz.sig \
	&& gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
	&& gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys Swift \
	&& gpg --batch --verify $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	# - Unpack the toolchain, set libs permissions, and clean up.
	&& SWIFT_PATH=$RUN_TOOL_CACHE/swift/5.9.2/x64 \
	&& mkdir -p $SWIFT_PATH \
	&& tar -xzf $RUNNER_TEMP/swift.tar.gz --directory $SWIFT_PATH --strip-components=1 \
	&& chmod -R o+r $SWIFT_PATH/usr/lib/swift \
	&& touch $SWIFT_PATH.complete \
	&& rm -rf "$GNUPGHOME" $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz



# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   4096R/ED3D1561 2019-03-22 [SC] [expires: 2023-03-23]
#       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org>
ARG SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561
ARG SWIFT_PLATFORM=ubuntu22.04
ARG SWIFT_BRANCH=swift-5.10-release
ARG SWIFT_VERSION=swift-5.10-RELEASE
ARG SWIFT_WEBROOT=https://download.swift.org

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
	SWIFT_PLATFORM=$SWIFT_PLATFORM \
	SWIFT_BRANCH=$SWIFT_BRANCH \
	SWIFT_VERSION=$SWIFT_VERSION \
	SWIFT_WEBROOT=$SWIFT_WEBROOT

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
	SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
	&& SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
	&& SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
	# - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -fsSL "$SWIFT_BIN_URL" -o $RUNNER_TEMP/swift.tar.gz "$SWIFT_SIG_URL" -o $RUNNER_TEMP/swift.tar.gz.sig \
	&& gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
	&& gpg --batch --verify $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz \
	# - Unpack the toolchain, set libs permissions, and clean up.
	&& SWIFT_PATH=$RUN_TOOL_CACHE/swift/5.10.0/x64 \
	&& mkdir -p $SWIFT_PATH \
	&& tar -xzf $RUNNER_TEMP/swift.tar.gz --directory $SWIFT_PATH --strip-components=1 \
	&& chmod -R o+r $SWIFT_PATH/usr/lib/swift \
	&& touch $SWIFT_PATH.complete \
	&& rm -rf "$GNUPGHOME" $RUNNER_TEMP/swift.tar.gz.sig $RUNNER_TEMP/swift.tar.gz

# Print Installed Swift Version
# RUN swift --version



ARG PYTHON_VERSION=3.12.3
ARG PYTHON_BRANCH=3.12.3-8625548520
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
	&& PYTHON_PATH=$RUN_TOOL_CACHE/Python/$PYTHON_VERSION/x64 \
	&& mkdir -p $PYTHON_PATH \
	&& tar -xzf $RUNNER_TEMP/python.tar.gz --directory $PYTHON_PATH --strip-components=1 \
	&& PYTHON_MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 1) \
	&& PYTHON_MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 2) \
	# - Create additional symlinks (Required for the UsePythonVersion Azure Pipelines task and the setup-python GitHub Action).
	&& ln -s $PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION $PYTHON_PATH/bin/python \
	&& ln -s $PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION $PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION$PYTHON_MINOR_VERSION \
	&& chmod +x $PYTHON_PATH/bin/python \
	$PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION \
	$PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION \
	$PYTHON_PATH/bin/python$PYTHON_MAJOR_VERSION$PYTHON_MINOR_VERSION \
	# - Upgrading pip...
	&& $PYTHON_PATH/bin/python -m ensurepip \
	&& $PYTHON_PATH/bin/python -m pip install --ignore-installed pip --disable-pip-version-check --no-warn-script-location --root-user-action=ignore \
	&& touch $PYTHON_PATH.complete \
	&& rm -rf $PYTHON_PATH/setup.sh \
	&& export PATH=$PYTHON_PATH/bin:$PATH

# Print Installed Python Version
# RUN python --version


SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]

ARG NODE_VERSION=18.20.2
ARG NODE_BRANCH=18.20.2-8647739097
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
	NODE_BIN_URL="$NODE_WEBROOT/$NODE_BRANCH/node-$NODE_VERSION-linux$OS_ARCH_SUFFIX.tar.gz" \
	# - Download the node.
	&& curl -fsSL "$NODE_BIN_URL" -o $RUNNER_TEMP/node.tar.gz \
	# - Unpack the node bin, set libs permissions, and clean up.
	&& NODE_PATH=$RUN_TOOL_CACHE/node/$NODE_VERSION/x64 \
	&& mkdir -p $NODE_PATH \
	&& tar -xzf $RUNNER_TEMP/node.tar.gz --directory $NODE_PATH --strip-components=1 \
	&& chmod -R o+r $NODE_PATH \
	&& touch $NODE_PATH.complete \
	&& rm -rf $RUNNER_TEMP/node.tar.gz \
	&& export PATH=$NODE_PATH/bin:$PATH \
	&& npm install -g npm@8 pnpm yarn

# Update PATH ENV
ENV PATH=$RUN_TOOL_CACHE/node/$NODE_VERSION/x64/bin:$PATH

# Print Installed Node Version
RUN node --version


RUN rm -rf $RUNNER_TEMP /var/cache/* /var/log/* /var/lib/apt/lists/*

USER $RUNNER