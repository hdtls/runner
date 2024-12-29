FROM ubuntu:latest
LABEL maintainer="Jeff (Junfeng Zhang) <jeff@tenbits.io>"
LABEL description="Docker Container for the GitHub Local Actions (act)."


ARG RUNNER=runner
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ARG RUNNER_TEMP=/home/$RUNNER/work/_temp
ARG RUNNER_ARCHITECTURE=x64

ENV RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE
ENV RUNNER_TEMP=$RUNNER_TEMP


# Add User and Groups
RUN useradd -U -G sudo -d /home/$RUNNER -m -s /bin/bash $RUNNER \
	&& echo "$RUNNER ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
	&& su - $RUNNER -c id \
	&& grep $RUNNER /etc/passwd \
	&& sed -i /etc/environment -e "s/USER=root/USER=$RUNNER/g"


RUN mkdir -m 0777 -p $RUNNER_TOOL_CACHE \
	&& chown -R $RUNNER:$RUNNER $RUNNER_TOOL_CACHE \
	&& mkdir -p $RUNNER_TEMP \
	&& chown -R $RUNNER:$RUNNER /home/$RUNNER/work


RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
	apt-get -q install -y \
	curl \
	git \
	nodejs \
	tzdata \
	yamllint \
	yq
RUN rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/*


ARG NODE_VERSION=22.12.0
# RUN env INPUT_NODE-VERSION=$NODE_VERSION \
# 	env INPUT_CHECK-LATEST=TRUE \
# 	bash -c "curl https://raw.githubusercontent.com/actions/setup-node/refs/heads/main/dist/setup/index.js | node"
# RUN	apt-get -q purge -y nodejs
# RUN chown -R $RUNNER:$RUNNER $RUNNER_TOOL_CACHE && chown -R $RUNNER:$RUNNER $RUNNER_TEMP

ARG NODE_BRANCH=22.12.0-12152383658
ARG NODE_WEBROOT=https://github.com/actions/node-versions/releases/download

RUN set -eux; \
	OS_ARCH_SUFFIX="-$RUNNER_ARCHITECTURE" \
	# NODE_VERSION=$(echo $NODE_BRANCH | cut -d '-' -f 1) \
	NODE_BIN_URL="$NODE_WEBROOT/$NODE_BRANCH/node-$NODE_VERSION-linux$OS_ARCH_SUFFIX.tar.gz" \
	# - Download the node.
	&& curl -fsSL "$NODE_BIN_URL" -o $RUNNER_TEMP/node.tar.gz \
	# - Unpack the node bin, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/$(echo $OS_ARCH_SUFFIX | cut -d '-' -f 2) \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& tar -xzf $RUNNER_TEMP/node.tar.gz --directory $TOOL_INSTALL_PREFIX --strip-components=1 \
	&& touch $TOOL_INSTALL_PREFIX.complete \
	&& chown -R $RUNNER:$RUNNER $RUNNER_TOOL_CACHE \
	&& rm -rf $RUNNER_TEMP/* \
	&& sed 's|"||g' -i "/etc/environment" \
	&& sed "s|^PATH=|PATH=$TOOL_INSTALL_PREFIX/bin:|mg" -i /etc/environment \
	&& . /etc/environment \
	&& npm install -g npm pnpm yarn \
	&& node --version
ENV PATH=$RUNNER_TOOL_CACHE/node/$NODE_VERSION/$RUNNER_ARCHITECTURE/bin:$PATH


ARG PYTHON_VERSION=3.13.1
# RUN env INPUT_PYTHON-VERSION=$PYTHON_VERSION \
# 	env INPUT_CHECK-LATEST=TRUE \
# 	env INPUT_ALLOW-PRERELEASES=FALSE \
# 	env INPUT_UPDATE-ENVIRONMENT=TRUE \
# 	bash -c "curl https://raw.githubusercontent.com/actions/setup-python/refs/heads/main/dist/setup/index.js | node"

ARG PYTHON_BRANCH=3.13.1-12154081405
ARG PYTHON_WEBROOT=https://github.com/actions/python-versions/releases/download

RUN set -eux; \
	OS_ARCH_SUFFIX="-$RUNNER_ARCHITECTURE" \
	PYTHON_BIN_URL="$PYTHON_WEBROOT/$PYTHON_BRANCH/python-$PYTHON_VERSION-linux-24.04$OS_ARCH_SUFFIX.tar.gz" \
	# - Download the python.
	&& curl -fsSL "$PYTHON_BIN_URL" -o $RUNNER_TEMP/python.tar.gz \
	# - Unpack the python bin, set libs permissions, and clean up.
	&& TOOL_INSTALL_PREFIX=$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$(echo $OS_ARCH_SUFFIX | cut -d '-' -f 2) \
	&& mkdir -p $TOOL_INSTALL_PREFIX \
	&& chown -R $RUNNER:$RUNNER $TOOL_INSTALL_PREFIX \
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
	&& chown -R $RUNNER:$RUNNER $RUNNER_TOOL_CACHE \
	&& rm -rf $TOOL_INSTALL_PREFIX/setup.sh \
	&& rm -rf $RUNNER_TEMP/* \
	&& sed "s|^PATH=|PATH=$TOOL_INSTALL_PREFIX/bin:|mg" -i /etc/environment \
	&& . /etc/environment \
	&& python3 --version
ENV PATH=/home/$RUNNER/.local/bin:$RUNNER_TOOL_CACHE/Python/$PYTHON_VERSION/$RUNNER_ARCHITECTURE/bin:$PATH


USER $RUNNER
