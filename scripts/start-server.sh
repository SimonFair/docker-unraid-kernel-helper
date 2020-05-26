#!/bin/bash
## Setting build variables
UNAME="$(uname -r)"
CUR_K_V="$(uname -r | cut -d '-' -f 1)"
MAIN_V="$(uname -r | cut -d '.' -f 1)"
if [ "$CPU_COUNT" == "all" ];then
	CPU_COUNT="$(grep -c ^processor /proc/cpuinfo)"
	echo "---Setting compile cores to $CPU_COUNT---"
else
	echo "---Setting compile cores to $CPU_COUNT---"
fi

## Check if custom mode is enabled
if [ "$CUSTOM_MODE" == "true" ]; then
	echo "-------------------------------------------------------------------"
	echo "------Custom mode enabled, putting container into sleep mode!------"
	echo "---Please connect to the console and build your Kernel manually!---"
	echo "------The basic script is copied over to your main directory!------"
	echo "-------------------------------------------------------------------"
	if [ ! -f ${DATA_DIR}/buildscript.sh ]; then
		cp /opt/scripts/start-server.sh ${DATA_DIR}/buildscript.sh
	fi
	sed -i '/## Check if custom mode is enabled/,+16 d' ${DATA_DIR}/buildscript.sh
	chmod +x ${DATA_DIR}/buildscript.sh
	chown -R ${UID}:${GID} ${DATA_DIR}
	chmod -R ${DATA_PERM} ${DATA_DIR}
	sleep infinity
fi

## Check for old Kernel output folder, if found stop container
if [ -d ${DATA_DIR}/output-$UNAME ]; then
	echo "-------------------------------------------------"
	echo "---Found old Kernel output folder v${UNAME%-*}---"
	echo "----Please delte this folder and restart the-----"
	echo "-------------container to continue!--------------"
	echo "-------------------------------------------------"
	chown -R ${UID}:${GID} ${DATA_DIR}/output-$UNAME
	chmod -R ${DATA_PERM} ${DATA_DIR}/output-$UNAME
	sleep infinity
fi

## Safety warning for 60 seconds
echo "------------------------------------------------------"
echo "-------------S A F E T Y   W A R N I N G--------------"
echo "---Don't shutdown your Server or Stop the container---"
echo "---if the process started and please wait until the---"
echo "-------ALL DONE message at the end appears, the-------"
echo "----------container will automatically stop.----------"
echo "----Also please backup your existing files if not-----"
echo "---selcted in the template. I'm not responsible if----"
echo "---you break your stuff, this container is only here--"
echo "---for your help, if something changes at building----"
echo "-------on Github or any other source that this--------"
echo "---container is using it could ruin the whole build---"
echo "------process. The build process begins after 60------"
echo "------seconds that this message first appeared--------"
echo "------------------------------------------------------"
if [ "${BUILD_NVIDIA}" == "true" ]; then
	echo
	echo "------------------------------------------------------"
	echo "---WARNING WARNING WARNING WARNING WARNING WARNING----"
	echo "------------------------------------------------------"
	echo "---nVidia driver build is enabled, please make sure---"
	echo "----that no process/container/VM uses the graphics----"
	echo "------card during the build process otherwise the-----"
	echo "----installation of the graphics driver will fail-----"
	echo "---and you are not able to use the graphics card------"
	echo "------------with the Docker containers!---------------"
	echo "------------------------------------------------------"
	echo "---I strongly recommend to shutdown all containers----"
	echo "-----during the build process for safety reasons!-----"
	echo "------------------------------------------------------"
	echo "---WARNING WARNING WARNING WARNING WARNING WARNING----"
	echo "------------------------------------------------------"
fi
sleep 60

if [ "${BUILD_DVB}" == "true" ]; then
	## Get latest version from DigitalDevices drivers
	if [ "${DD_DRV_V}" == "latest" ]; then
		echo "---Trying to get latest verson for DigitalDevices driver---"
		DD_DRV_V="$(curl -s https://api.github.com/repos/DigitalDevices/dddvb/releases/latest | grep tag_name | cut -d '"' -f4)"
		if [ -z $DD_DRV_V ]; then
			echo "---Can't get latest version for DigitalDevices driver, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for DigitalDevices driver: v$DD_DRV_V---"
	else
		echo "---DigitalDevices driver manually set to: v$DD_DRV_V---"
	fi

	## Get latest version from LibreELEC drivers
	if [ "${LE_DRV_V}" == "latest" ]; then
		echo "---Trying to get latest verson for LibreELEC driver---"
		LE_DRV_V="$(curl -s https://api.github.com/repos/LibreELEC/dvb-firmware/releases/latest | grep tag_name | cut -d '"' -f4)"
		if [ -z $LE_DRV_V ]; then
			echo "---Can't get latest version for LibreELEC driver, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for LibreELEC driver: v$LE_DRV_V---"
	else
		echo "---LibreELEC driver manually set to: v$LE_DRV_V---"
	fi
else
	echo "---Build of DVB driver/modules/firmware skipped!---"
fi

if [ "${BUILD_NVIDIA}" == "true" ]; then
	## Get latest version from nVidia drivers
	if [ "${NV_DRV_V}" == "latest" ]; then
		echo "---Trying to get latest verson for nVidia driver---"
		NV_DRV_V="$(curl -s http://download.nvidia.com/XFree86/Linux-x86_64/latest.txt | cut -d ' ' -f1)"
		if [ -z $NV_DRV_V ]; then
			echo "---Can't get latest version for nVidia driver, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for nVidia driver: v$NV_DRV_V---"
	else
		echo "---nVidia driver manually set to: v$NV_DRV_V---"
	fi

	## Get latest version from Seccomp
	if [ "${SECCOMP_V}" == "latest" ]; then
		echo "---Trying to get latest verson for Seccomp---"
		SECCOMP_V="$(curl -s https://api.github.com/repos/seccomp/libseccomp/releases/latest | grep tag_name | cut -d '"' -f4 | cut -d 'v' -f2)"
		if [ -z $SECCOMP_V ]; then
			echo "---Can't get latest version for Seccomp, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for Seccomp: v$SECCOMP_V---"
	else
		echo "---Seccomp manually set to: v$SECCOMP_V---"
	fi

	## Get latest version from 'nvidia-container-runtime'
	if [ "${NVIDIA_CONTAINER_RUNTIME_V}" == "latest" ]; then
		echo "---Trying to get latest verson for 'nvidia-container-runtime' driver---"
		NVIDIA_CONTAINER_RUNTIME_V="$(curl -s https://api.github.com/repos/NVIDIA/nvidia-container-runtime/releases/latest | grep tag_name | cut -d '"' -f4 | cut -d 'v' -f2)"
		if [ -z $NVIDIA_CONTAINER_RUNTIME_V ]; then
			echo "---Can't get latest version for 'nvidia-container-runtime', putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for 'nvidia-container-runtime': v$NVIDIA_CONTAINER_RUNTIME_V---"
	else
		echo "---'nvidia-container-runtime' manually set to: v$NVIDIA_CONTAINER_RUNTIME_V---"
	fi

	## Get latest version from 'nvidia-toolkit'
	if [ "${CONTAINER_TOOLKIT_V}" == "latest" ]; then
		echo "---Trying to get latest verson for 'nvidia-toolkit' driver---"
		CONTAINER_TOOLKIT_V="$(curl -s https://api.github.com/repos/NVIDIA/container-toolkit/releases/latest | grep tag_name | cut -d '"' -f4 | cut -d 'v' -f2)"
		if [ -z $CONTAINER_TOOLKIT_V ]; then
			echo "---Can't get latest version for 'nvidia-toolkit', putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for 'nvidia-toolkit': v$CONTAINER_TOOLKIT_V---"
	else
		echo "---'nvidia-toolkit' manually set to: v$CONTAINER_TOOLKIT_V---"
	fi

	## Get latest version from 'libnvidia-container'
	if [ "${LIBNVIDIA_CONTAINER_V}" == "latest" ]; then
		echo "---Trying to get latest verson for 'libnvidia-container'---"
		LIBNVIDIA_CONTAINER_V="$(curl -s https://api.github.com/repos/NVIDIA/libnvidia-container/releases/latest | grep tag_name | cut -d '"' -f4 | cut -d 'v' -f2)"
		if [ -z $LIBNVIDIA_CONTAINER_V ]; then
			echo "---Can't get latest version for 'libnvidia-container', putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Latest version for 'libnvidia-container': v$LIBNVIDIA_CONTAINER_V---"
	else
		echo "---'libnvidia-container' manually set to: v$LIBNVIDIA_CONTAINER_V---"
	fi
else
	echo "---Build of nVidia drivers/modules skipped!---"
fi

## Check if images of Stock Unraid version are present or download them if default path is /usr/src/stock
if [ "$IMAGES_FILE_PATH" == "/usr/src/stock" ]; then
	if [ ! -d ${DATA_DIR}/stock/${UNRAID_V} ]; then
		mkdir -p ${DATA_DIR}/stock/${UNRAID_V}
	fi
	if [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzroot ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzimage ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzmodules ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzfirmware ]; then
		cd ${DATA_DIR}/stock/${UNRAID_V}
		echo "---One or more Stock Unraid v${UNRAID_V} files not found, downloading...---"
		if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip "https://s3.amazonaws.com/dnld.lime-technology.com/stable/unRAIDServer-${UNRAID_V}-x86_64.zip" ; then
				echo "---Successfully downloaded Stock Unraid v${UNRAID_V}---"
			else
				echo "---Download of Stock Unraid v${UNRAID_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		elif [ ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
			echo "---unRAIDServer-${UNRAID_V}-x86_64.zip found locally---"
			mv ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
		fi
		echo "---Extracting files---"
		unzip -o ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
		if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
			mv ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}
		fi
		find . -maxdepth 1 -not -name 'bz*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
		rm ${DATA_DIR}/stock/${UNRAID_V}/*.sha256
	fi
	IMAGES_FILE_PATH=${DATA_DIR}/stock/${UNRAID_V}
fi

## Create output folder
if [ ! -d ${DATA_DIR}/output-$UNAME ]; then
	mkdir ${DATA_DIR}/output-$UNAME
fi

## Preparing directorys modules and firmware
if [ -d /lib/modules ]; then
	rm -R /lib/modules
fi
mkdir /lib/modules
if [ -d /lib/firmware ]; then
	rm -R /lib/firmware
fi
mkdir /lib/firmware

## Extracting Stock Unraid images to modules and firmware
if [ ! -f $IMAGES_FILE_PATH/bzmodules ]; then
	echo "---Can't find 'bzmodules', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
unsquashfs -f -d /lib/modules $IMAGES_FILE_PATH/bzmodules

if [ ! -f $IMAGES_FILE_PATH/bzfirmware ]; then
	echo "---Can't find 'bzfirmware', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
unsquashfs -f -d /lib/firmware $IMAGES_FILE_PATH/bzfirmware

## Download Kernel to data directory & extract it if not present
cd ${DATA_DIR}
if [ ! -d ${DATA_DIR}/linux-$UNAME ]; then
	mkdir ${DATA_DIR}/linux-$UNAME
fi
if [ ! -f ${DATA_DIR}/linux-$CUR_K_V.tar.gz ]; then
	echo "---Downloading Kernel v${UNAME%-*}---"
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://mirrors.edge.kernel.org/pub/linux/kernel/v$MAIN_V.x/linux-$CUR_K_V.tar.gz ; then
		echo "---Successfully downloaded Kernel v${UNAME%-*}---"
	else
		echo "---Download of Kernel v${UNAME%-*} failed, putting container into sleep mode!---"
		sleep infinity
	fi
	echo "---Extracting Kernel v${UNAME%-*}, this can take some time, please wait!---"
	tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf ${DATA_DIR}/linux-$CUR_K_V.tar.gz
else
	echo "---Found Kernel v${UNAME%-*} locally, extracting, this can take some time, please wait!---"
	tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf linux-$CUR_K_V.tar.gz
fi

## Copy patches & config to new Kernel directory
echo "---Copying Patches and Config file to the Kernel---"
rsync -av /host/usr/src/linux-*/ ${DATA_DIR}/linux-$UNAME

## Apply changes to .config
if [ "${BUILD_DVB}" == "true" ]; then
	cd ${DATA_DIR}/linux-$UNAME
	echo "---Patching necessary files for 'dvb', this can take some time, please wait!---"
	while read -r line
	do
		line_conf=${line//# /}
		line_conf=${line_conf%%=*}
		line_conf=${line_conf%% *}
		sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
		echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
	done < "${DATA_DIR}/deps/dvb.list"
fi

if [ "${BUILD_NVIDIA}" == "true" ]; then
	echo "---Patching necessary files for 'joydev', this can take some time, please wait!---"
	while read -r line
	do
		line_conf=${line//# /}
		line_conf=${line_conf%%=*}
		line_conf=${line_conf%% *}
		sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
		echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
	done < "${DATA_DIR}/deps/joydev.list"
fi

## Apply patches
echo "---Applying patches to Kernel, please wait!---"
cd ${DATA_DIR}/linux-$UNAME
find ${DATA_DIR}/linux-$UNAME -type f -iname '*.patch' -print0|xargs -n1 -0 patch -p 1 -i

## Make oldconfig
cd ${DATA_DIR}/linux-$UNAME
make oldconfig

echo "---Starting to build Kernel v${UNAME%-*} in 10 seconds, this can take some time, please wait!---"
sleep 10
cd ${DATA_DIR}/linux-$UNAME
make -j${CPU_COUNT}

echo "---Starting to install Kernel Modules in 10 seconds, please wait!---"
sleep 10
cd ${DATA_DIR}/linux-$UNAME
make modules_install

## Copy Kernel image to output folder
echo "---Copying Kernel Image to output folder---"
cp ${DATA_DIR}/linux-$UNAME/arch/x86_64/boot/bzImage ${DATA_DIR}/output-$UNAME/bzimage

if [ "${BUILD_DVB}" == "true" ]; then
	## Download and install DigitalDevices drivers
	echo "---Downloading DigitalDevices drivers v${DD_DRV_V}, please wait!---"
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/dd-v${DD_DRV_V} ]; then
		mkdir ${DATA_DIR}/dd-v${DD_DRV_V}
	fi
	if [ ! -f ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz ]; then
		echo "---Downloading DigitalDevices driver v${DD_DRV_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz https://github.com/DigitalDevices/dddvb/archive/${DD_DRV_V}.tar.gz ; then
			echo "---Successfully downloaded DigitalDevices drivers v${DD_DRV_V}---"
		else
			echo "---Download of DigitalDevices driver v${DD_DRV_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---DigitalDevices driver v${DD_DRV_V} found locally---"
	fi
	tar -C ${DATA_DIR}/dd-v${DD_DRV_V} --strip-components=1 -xf ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz
	cd ${DATA_DIR}/dd-v${DD_DRV_V}
	make -j${CPU_COUNT}
	make install

	## Download and install Xbox One Digital TV Tuner firwmare
	## https://www.linuxtv.org/wiki/index.php/Xbox_One_Digital_TV_Tuner
	cd /lib/firmware
	if wget -q -nc --show-progress --progress=bar:force:noscroll "http://linuxtv.org/downloads/firmware/dvb-usb-dib0700-1.20.fw" ; then
			echo "---Successfully downloaded Xbox One Digital TV Tuner firmware 'dvb-usb-dib0700-1.20.fw'---"
	else
		echo "---Download of Xbox One Digital TV Tuner firmware 'dvb-usb-dib0700-1.20.fw' failed, putting container into sleep mode!---"
		sleep infinity
	fi
	if wget -q -nc --show-progress --progress=bar:force:noscroll "http://palosaari.fi/linux/v4l-dvb/firmware/MN88472/02/latest/dvb-demod-mn88472-02.fw" ; then
			echo "---Successfully downloaded Xbox One Digital TV Tuner firmware 'dvb-demod-mn88472-02.fw'---"
	else
		echo "---Download of Xbox One Digital TV Tuner firmware 'dvb-demod-mn88472-02.fw' failed, putting container into sleep mode!---"
		sleep infinity
	fi

	## Download and install LibreELEC drivers
	## https://github.com/LibreELEC/dvb-firmware
	echo "---Downloading LibreELEC drivers v${LE_DRV_V}, please wait!---"
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/lE-v${LE_DRV_V} ]; then
		mkdir ${DATA_DIR}/lE-v${LE_DRV_V}
	fi
	if [ ! -f ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz ]; then
		echo "---Downloading LibreELEC driver v${LE_DRV_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz https://github.com/LibreELEC/dvb-firmware/archive/${LE_DRV_V}.tar.gz ; then
			echo "---Successfully downloaded LibreELEC drivers v${LE_DRV_V}---"
		else
			echo "---Download of LibreELEC driver v${LE_DRV_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---LibreELEC driver v${LE_DRV_V} found locally---"
	fi
	tar -C ${DATA_DIR}/lE-v${LE_DRV_V} --strip-components=1 -xf ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz
	rsync -av ${DATA_DIR}/lE-v${LE_DRV_V}/firmware/ /lib/firmware/
fi

## Decompress bzroot
echo "---Decompressing bzroot, this can take some time, please wait!---"
if [ ! -d ${DATA_DIR}/bzroot-extracted-$UNAME ]; then
	mkdir ${DATA_DIR}/bzroot-extracted-$UNAME
fi
if [ ! -f $IMAGES_FILE_PATH/bzroot ]; then
	echo "---Can't find 'bzroot', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
cd ${DATA_DIR}/bzroot-extracted-$UNAME
dd if=$IMAGES_FILE_PATH/bzroot bs=512 count=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') of=${DATA_DIR}/output-$UNAME/bzroot
dd if=$IMAGES_FILE_PATH/bzroot bs=512 skip=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') | xzcat | cpio -i -d -H newc --no-absolute-filenames

if [ "${BUILD_NVIDIA}" == "true" ]; then
	## Nvidia Drivers & Kernel module installation
	cd ${DATA_DIR}
	if [ ! -f ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run ]; then
		echo "---Downloading nVidia driver v${NV_DRV_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run http://download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run ; then
			echo "---Successfully downloaded nVidia driver v${NV_DRV_V}---"
		else
			echo "---Download of nVidia driver v${NV_DRV_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---nVidia driver v${NV_DRV_V} found locally---"
	fi
	chmod +x ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run
	echo "---Installing nVidia Driver and Kernel Module v${NV_DRV_V}, please wait!---"
	${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run --kernel-name=$UNAME \
		--no-precompiled-interface \
		--disable-nouveau \
		--x-library-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--opengl-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--installer-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--utility-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--documentation-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--application-profile-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr/share \
		--proc-mount-point=${DATA_DIR}/bzroot-extracted-$UNAME/proc \
		--compat32-libdir=${DATA_DIR}/bzroot-extracted-$UNAME/usr/lib \
		--j${CPU_COUNT} \
		--silent

	## Copying 'nvidia-modprobe' and OpenCL icd
	cp /usr/bin/nvidia-modprobe ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin/
	cp -R /etc/OpenCL ${DATA_DIR}/bzroot-extracted-$UNAME/etc/

	## Compile 'libnvidia-container'
	echo "---Compiling 'libnvidia-container', this can take some time, please wait!---"
	cd ${DATA_DIR}
	git clone https://github.com/NVIDIA/libnvidia-container.git
	cd ${DATA_DIR}/libnvidia-container
	git checkout v$LIBNVIDIA_CONTAINER_V
	sed -i '/if (syscall(SYS_pivot_root, ".", ".") < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c
	sed -i '/if (umount2(".", MNT_DETACH) < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c
	DESTDIR=${DATA_DIR}/bzroot-extracted-$UNAME make install prefix=/usr

	## Create Docker daemon config file
	mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/docker
	tee ${DATA_DIR}/bzroot-extracted-$UNAME/etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

	## Select build process for 'nvidia-container-runtime' & 'nvidia-container-toolkit'
	if [ "${NVIDIA_CONTAINER_RUNTIME_V//./}" -le "314" ]; then
		## Compile 'nvidia-container-toolkit' v3.1.4 and lower
		echo "---Compiling 'nvidia-container-toolkit', this can take some time, please wait!---"
		mkdir -p ${DATA_DIR}/go/src/github.com/NVIDIA
		cd ${DATA_DIR}/go/src/github.com/NVIDIA
		git clone https://github.com/NVIDIA/nvidia-container-runtime.git
		cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime
		git checkout v$NVIDIA_CONTAINER_RUNTIME_V
		go build -ldflags "-s -w" -v github.com/NVIDIA/nvidia-container-runtime/toolkit/nvidia-container-toolkit
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/nvidia-container-toolkit ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
		cd ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
		ln -s /usr/bin/nvidia-container-toolkit nvidia-container-runtime-hook
		mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/toolkit/config.toml.debian ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
		sed -i '/#path/c\path = "/usr/bin/nvidia-container-cli"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
		sed -i '/#ldcache/c\ldcache = "/etc/ld.so.cache"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml

		### Compile 'nvidia-container-runtime' v3.1.4 and lower
		echo "---Compiling 'nvidia-container-runtime', this can take some time, please wait!---"
		cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src
		make
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src/nvidia-container-runtime ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
	else
		### Compile 'nvidia-container-runtime' v3.2.0 and up
		echo "---Compiling 'nvidia-container-runtime', this can take some time, please wait!---"
		mkdir -p ${DATA_DIR}/go/src/github.com/NVIDIA
		cd ${DATA_DIR}/go/src/github.com/NVIDIA
		git clone https://github.com/NVIDIA/nvidia-container-runtime.git
		cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime
		git checkout v$NVIDIA_CONTAINER_RUNTIME_V
		cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/src
		make build
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/src/nvidia-container-runtime ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin

		### Compile 'nvidia-container-toolkit' v3.2.0 and up
		echo "---Compiling 'container-toolkit', this can take some time, please wait!---"
		cd ${DATA_DIR}/go/src/github.com/NVIDIA
		git clone https://github.com/NVIDIA/container-toolkit
		cd ${DATA_DIR}/go/src/github.com/NVIDIA/container-toolkit
		git checkout v$CONTAINER_TOOLKIT_V
		make binary
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/container-toolkit/nvidia-container-toolkit ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
		cd ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
		ln -s /usr/bin/nvidia-container-toolkit nvidia-container-runtime-hook
		mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime
		cp ${DATA_DIR}/go/src/github.com/NVIDIA/container-toolkit/config/config.toml.debian ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
		sed -i '/#path/c\path = "/usr/bin/nvidia-container-cli"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
		sed -i '/#ldcache/c\ldcache = "/etc/ld.so.cache"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
	fi

	### Install Seccomp
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/seccomp-v${SECCOMP_V} ]; then
		mkdir ${DATA_DIR}/seccomp-v${SECCOMP_V}
	fi
	if [ ! -f ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz ]; then
		echo "---Downloading Seccomp v${SECCOMP_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz https://github.com/seccomp/libseccomp/releases/download/v$SECCOMP_V/libseccomp-${SECCOMP_V}.tar.gz ; then
			echo "---Successfully downloaded Seccomp v${SECCOMP_V}---"
		else
			echo "---Download of Seccomp v${SECCOMP_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---Seccomp found locally---"
	fi
	tar -C ${DATA_DIR}/seccomp-v${SECCOMP_V} --strip-components=1 -xf ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz
	cd ${DATA_DIR}/seccomp-v${SECCOMP_V}
	${DATA_DIR}/seccomp-v${SECCOMP_V}/configure --prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr --disable-static
	make
	make install
fi

## Create bzmodules
echo "---Generating bzmodules in output folder---"
mksquashfs /lib/modules/$UNAME/ ${DATA_DIR}/output-$UNAME/bzmodules -keep-as-directory -noappend

## Create bzfirmware
#echo "---Generating bzfirmware in output folder---"
mksquashfs /lib/firmware ${DATA_DIR}/output-$UNAME/bzfirmware -noappend

## Compress bzroot image
echo "---Creating 'bzroot', this can take some time, please wait!---"
cd ${DATA_DIR}/bzroot-extracted-$UNAME
find . | cpio -o -H newc | xz --format=lzma >> ${DATA_DIR}/output-$UNAME/bzroot

## Generate checksums
echo "---Generationg checksums---"
if [ -f ${DATA_DIR}/output-$UNAME/bzimage ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzimage > ${DATA_DIR}/output-$UNAME/bzimage.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzmodules ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzmodules > ${DATA_DIR}/output-$UNAME/bzmodules.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzfirmware ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzfirmware > ${DATA_DIR}/output-$UNAME/bzfirmware.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzroot ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzroot > ${DATA_DIR}/output-$UNAME/bzroot.sha256
fi

## Cleanup
if [ "$CLEANUP" == "full" ]; then
	echo "---Cleaning up, only output folder will be not deleted---"
	cd ${DATA_DIR}
	find . -maxdepth 1 -not -name 'output*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm -R /lib/modules
	rm -R /lib/firmware
elif [ "$CLEANUP" == "moderate" ]; then
	echo "---Cleaning up, downloads are not deleted---"
	cd ${DATA_DIR}
	find . -maxdepth 1 -type d -not -name 'output*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm -R /lib/modules
	rm -R /lib/firmware
else
	echo "---Nothing to clean, no cleanup selected---"
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm -R /lib/modules
	rm -R /lib/firmware
fi

## Creating backup from now installed images if selected
if [ "$CREATE_BACKUP" == "true" ]; then
	if [ ! -d ${DATA_DIR}/backup-$UNAME ]; then
		mkdir ${DATA_DIR}/backup-$UNAME
	fi
	echo "---Creating backup of now installed image files to backup folder, please wait!---"
	cp /host/boot/bzimage ${DATA_DIR}/backup-$UNAME/bzimage
	cp /host/boot/bzmodules ${DATA_DIR}/backup-$UNAME/bzmodules
	cp /host/boot/bzfirmware ${DATA_DIR}/backup-$UNAME/bzfirmware
	cp /host/boot/bzroot ${DATA_DIR}/backup-$UNAME/bzroot
	cp /host/boot/bzroot-gui ${DATA_DIR}/backup-$UNAME/bzroot-gui
	cp /host/boot/*.sha256 ${DATA_DIR}/backup-$UNAME/
else
	echo "---No backup creation selected, please be sure to backup your images!---"
fi

## Fixing permissions
echo "---Fixing permissions, please wait---"
chown -R ${UID}:${GID} ${DATA_DIR}
chmod -R ${DATA_PERM} ${DATA_DIR}

## End message
echo
echo
echo
echo "-----------------------------------------------"
echo "-----The built images are located in your------"
echo "----output folder: 'output-$UNAME'----"
echo "-----------------------------------------------"
if [ "${CUSTOM_MODE}" == "true" ]; then
	echo "-----The images were built with CUSTOM_MODE----"
	echo "-------------------enabled!--------------------"
else
	echo "---The images were built with the following----"
	echo "------build options and version numbers:-------"
	if [ "${BUILD_NVIDIA}" == "true" ]; then
		echo "--------nVidia driver version: $NV_DRV_V---------"
		echo "------lib-nvidia-container version: $LIBNVIDIA_CONTAINER_V------"
		echo "----nvidia-container-runtime version: $NVIDIA_CONTAINER_RUNTIME_V----"
		if [ "${NVIDIA_CONTAINER_RUNTIME_V//./}" -ge "320" ]; then
			echo "--------container-toolkit version: $CONTAINER_TOOLKIT_V-------"
		fi
		echo "------------Seccomp version: $SECCOMP_V-------------"
	fi
	if [ "${BUILD_DVB}" == "true" ]; then
		echo "-----DigitalDevices driver version: $DD_DRV_V-----"
		echo "--------LibreELEC driver version: $LE_DRV_V--------"
		echo "------Xbox One Digital TV Tuner firwmare-------"
	fi
fi
echo "-----------------------------------------------"
echo
echo
echo
echo
echo "-----------------------------------------------"
echo "----------------A L L   D O N E----------------"
echo "---Please copy the generated files from the----"
echo "----output folder to your Unraid USB Stick-----"
echo "-----------------------------------------------"
echo "----MAKE SURE TO BACKUP YOUR OLD FILES FROM----"
echo "----YOUR UNRAID USB STICK IN CASE SOMETHING----"
echo "------WENT WRONG WITH THE KERNEL COMPILING-----"
echo "-----------------------------------------------"