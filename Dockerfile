FROM ich777/debian-baseimage

LABEL maintainer="admin@minenet.at"

RUN	echo "deb http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list && \
	apt-get update && \
	apt-get -y install nano make gcc-9 bison flex bc libelf-dev squashfs-tools patch build-essential kmod cpio libncurses5-dev unzip rsync git curl bmake lsb-release libseccomp-dev libcap-dev pkg-config patchutils uuid-dev libblkid-dev libssl-dev dh-autoreconf libproc-processtable-perl beep zip libibmad-dev python3-setuptools && \
	cd /tmp && \
	wget -q -nc --show-progress --progress=bar:force:noscroll -O go.tar.gz https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz && \
	tar -C /usr/local -xvzf go.tar.gz && \
	export PATH=$PATH:/usr/local/go/bin && \
	rm -R /tmp/go* && \
	rm -R /lib/x86_64-linux-gnu/liblzma.* && \
	wget -q -nc --show-progress --progress=bar:force:noscroll -O xz.tar https://github.com/ich777/docker-unraid-kernel-helper/raw/6.9.0/xz.tar && \
	tar -C / -xvf /tmp/xz.tar && \
	rm /tmp/xz.tar && \
	wget -q -nc --show-progress --progress=bar:force:noscroll https://github.com/ich777/python-unraid/raw/3.8.4rc1/python-3.8.4rc1-x86_64-1.tgz && \
	wget -q -nc --show-progress --progress=bar:force:noscroll https://github.com/ich777/python-unraid/raw/3.7.3/gobject-introspection-1.46.0-x86_64-1.txz && \
	rm -rf /var/lib/apt/lists/*

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