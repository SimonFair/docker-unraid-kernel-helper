FROM ich777/debian-baseimage:arm64

LABEL maintainer="admin@minenet.at"

RUN	echo "deb http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list && \
	apt-get update && \
	apt-get -y install nano make gcc-9 bison flex bc libelf-dev squashfs-tools patch build-essential kmod cpio libncurses5-dev unzip rsync git curl bmake lsb-release libseccomp-dev libcap-dev pkg-config patchutils uuid-dev libblkid-dev libssl-dev dh-autoreconf libproc-processtable-perl beep zip libibmad-dev python3-dev python3-setuptools gperf && \
	cd /tmp && \
	wget -q -nc --show-progress --progress=bar:force:noscroll -O go.tar.gz https://golang.org/dl/go1.15.2.linux-arm64.tar.gz && \
	tar -C /usr/local -xvzf go.tar.gz && \
	export PATH=$PATH:/usr/local/go/bin && \
	rm -R /tmp/go* && \
	rm -rf /var/lib/apt/lists/*

RUN LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/xz-archiver | grep LATEST | cut -d '=' -f2)" && \
	rm -R /lib/aarch64-linux-gnu/liblzma.* && \
	cd /tmp && \
	wget -q -nc --show-progress --progress=bar:force:noscroll -O xz.tar.gz https://github.com/ich777/xz/releases/download/$LAT_V/xz-v$LAT_V-arm64.tar.gz && \
	tar -C / -xvf /tmp/xz.tar.gz && \
	rm /tmp/xz.tar.gz && \
	wget -q -nc --show-progress --progress=bar:force:noscroll https://github.com/ich777/cpython/releases/download/3.8.5/python-v3.8.5-arm64-1.tgz

ENV DATA_DIR="/usr/src"
ENV UNRAID_V=6.9.0
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/usr/src/go/
ENV IMAGES_FILE_PATH="/usr/src/stock"
ENV BUILD_DVB="true"
ENV BUILD_NVIDIA="true"
ENV BUILD_ZFS="false"
ENV BUILD_ISCSI="false"
ENV BUILD_MLX_MFT="false"
ENV ENABLE_i915="false"
ENV BUILD_JOYDEV="false"
ENV LIBNVIDIA_CONTAINER_V="latest"
ENV NVIDIA_CONTAINER_RUNTIME_V="latest"
ENV CONTAINER_TOOLKIT_V="latest"
ENV CUSTOM_MODE=""
ENV USER_PATCHES=""
ENV DD_DRV_V="latest"
ENV LE_DRV_V="latest"
ENV NV_DRV_V="latest"
ENV SECCOMP_V="latest"
ENV ZFS_V="master"
ENV TARGETCLI_FB_V="latest"
ENV RTSLIB_FB_V="latest"
ENV CONFIGSHELL_FB_V="latest"
ENV MLX_MFT_V="latest"
ENV CLEANUP="full"
ENV CREATE_BACKUP="true"
ENV UNAME=""
ENV BETA_BUILD=""
ENV BEEP="true"
ENV SAVE_LOG="false"
ENV BUILD_FROM_SOURCE="false"
ENV DONTWAIT=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="kernel"

RUN mkdir -p $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
ADD /deps/ /tmp/deps/
RUN chmod -R 770 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]