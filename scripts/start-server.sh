#!/bin/bash
if [ "$CUSTOM_MODE" == "true" ]; then
	echo "-------------------------------------------------------------------"
	echo "------Custom mode enabled, putting container into sleep mode!------"
	echo "---Please connect to the console and build your Kernel manually!---"
	echo "------The basic script is copied over to your main directory!------"
	echo "-------------------------------------------------------------------"
	cp /opt/scripts/start-server.sh ${DATA_DIR}/buildscript.sh
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
echo "----break your stuff, this container is only here-----"
echo "---for your help, if something changes at building----"
echo "-------on Github or any other source that this--------"
echo "---container is using it could ruin the whole build---"
echo "------process. The build process begins after 60------"
echo "-----------that this message first appeared-----------"
echo "------------------------------------------------------"
sleep 60

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

## Get latest version from DigitalDevices drivers
if [ "${DD_DRV_V}" == "latest" ]; then
	echo "---Trying to get latest verson for DigitalDevices Driver---"
	DD_DRV_V="$(curl -s https://api.github.com/repos/DigitalDevices/dddvb/releases/latest | grep tag_name | cut -d '"' -f4)"
	if [ -z $DD_DRV_V ]; then
		echo "---Can't get latest version for DigitalDevices Driver, putting container into sleep mode!---"
		sleep infinity
	fi
	echo "---Latest version for DigitalDevices Driver: v$DD_DRV_V---"
else
	echo "---DigitalDevices Driver manually set to: v$DD_DRV_V---"
fi

## Get latest version from nVidia drivers
if [ "${NV_DRV_V}" == "latest" ]; then
	echo "---Trying to get latest verson for Nvidia Driver---"
	NV_DRV_V="$(curl -s http://download.nvidia.com/XFree86/Linux-x86_64/latest.txt | cut -d ' ' -f1)"
	if [ -z $NV_DRV_V ]; then
		echo "---Can't get latest version for Nvidia Driver, putting container into sleep mode!---"
		sleep infinity
	fi
	echo "---Latest version for Nvidia Driver: v$NV_DRV_V---"
else
	echo "---Nvidia Driver manually set to: v$NV_DRV_V---"
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

## Check if images of Stock Unraid version are present or download them if default path is /usr/src/stock
if [ "$IMAGES_FILE_PATH" == "/usr/src/stock" ]; then
	if [ ! -d ${DATA_DIR}/stock/${UNRAID_V} ]; then
		mkdir -p ${DATA_DIR}/stock/${UNRAID_V}
	fi
	if [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzroot ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzimage ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzmodules ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzfirmware ]; then
		cd ${DATA_DIR}/stock/${UNRAID_V}
		echo "---One or more Stock Unraid v${UNRAID_V} files not found, downloading...---"
		if [ ! -f ${DATA_DIR}/stock/unRAIDServer-${UNRAID_V}-x86_64.zip ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}/stock/ https://s3.amazonaws.com/dnld.lime-technology.com/stable/unRAIDServer-${UNRAID_V}-x86_64.zip ; then
				echo "---Successfully downloaded Stock Unraid v${UNRAID_V}---"
			else
				echo "---Download of Stock Unraid v${UNRAID_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		elif [ ${DATA_DIR}/stock/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
        	mv ${DATA_DIR}/stock/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
		else
			echo "---unRAIDServer-${UNRAID_V}-x86_64.zip found locally---"
		fi
		echo "---Extracting files---"
		unzip -o ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
		mv ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}
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
unsquashfs -f -d /lib/modules $IMAGES_FILE_PATH/bzmodules
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

### Patching Modules
## DVB
modules_dvb="CONFIG_ALTERA_STAPL=m
CONFIG_FIREWIRE=m
CONFIG_FIREWIRE_OHCI=m
CONFIG_FIREWIRE_SBP2=m
CONFIG_FIREWIRE_NET=m
# CONFIG_NET_VENDOR_CISCO is not set
CONFIG_IGB=m
CONFIG_IGB_HWMON=y
CONFIG_IGBVF=m
CONFIG_INPUT_LEDS=m
# CONFIG_KEYBOARD_LM8323 is not set
# CONFIG_KEYBOARD_TM2_TOUCHKEY is not set
# CONFIG_INPUT_APANEL is not set
# CONFIG_INPUT_IMS_PCU is not set
CONFIG_SERIO_SERPORT=m
# CONFIG_SENSORS_IBM_CFFPS is not set
CONFIG_MFD_CORE=m
CONFIG_MFD_WL1273_CORE=m
CONFIG_CEC_CORE=m
CONFIG_LIRC=y
CONFIG_IR_IMON_DECODER=y
CONFIG_RC_DEVICES=y
CONFIG_RC_ATI_REMOTE=m
CONFIG_IR_ENE=m
CONFIG_IR_IMON=m
CONFIG_IR_IMON_RAW=m
CONFIG_IR_MCEUSB=m
CONFIG_IR_ITE_CIR=m
CONFIG_IR_FINTEK=m
CONFIG_IR_NUVOTON=m
CONFIG_IR_REDRAT3=m
CONFIG_IR_STREAMZAP=m
CONFIG_IR_WINBOND_CIR=m
CONFIG_IR_IGORPLUGUSB=m
CONFIG_IR_IGUANA=m
CONFIG_IR_TTUSBIR=m
CONFIG_RC_LOOPBACK=m
CONFIG_IR_SERIAL=m
CONFIG_IR_SERIAL_TRANSMITTER=y
CONFIG_IR_SIR=m
CONFIG_MEDIA_ANALOG_TV_SUPPORT=y
CONFIG_MEDIA_DIGITAL_TV_SUPPORT=y
CONFIG_MEDIA_RADIO_SUPPORT=y
CONFIG_MEDIA_SDR_SUPPORT=y
CONFIG_MEDIA_CEC_SUPPORT=y
# CONFIG_MEDIA_CEC_RC is not set
CONFIG_MEDIA_CONTROLLER=y
# CONFIG_MEDIA_CONTROLLER_DVB is not set
CONFIG_VIDEO_V4L2_SUBDEV_API=y
CONFIG_VIDEO_ADV_DEBUG=y
CONFIG_VIDEO_FIXED_MINOR_RANGES=y
CONFIG_VIDEO_PCI_SKELETON=m
CONFIG_VIDEO_TUNER=m
CONFIG_V4L2_MEM2MEM_DEV=m
CONFIG_V4L2_FWNODE=m
CONFIG_VIDEOBUF_GEN=m
CONFIG_VIDEOBUF_DMA_SG=m
CONFIG_VIDEOBUF_VMALLOC=m
CONFIG_DVB_CORE=m
# CONFIG_DVB_MMAP is not set
CONFIG_DVB_NET=y
CONFIG_TTPCI_EEPROM=m
CONFIG_DVB_MAX_ADAPTERS=16
CONFIG_DVB_DYNAMIC_MINORS=y
CONFIG_DVB_DEMUX_SECTION_LOSS_LOG=y
CONFIG_DVB_ULE_DEBUG=y
CONFIG_MEDIA_USB_SUPPORT=y
CONFIG_USB_VIDEO_CLASS=m
CONFIG_USB_VIDEO_CLASS_INPUT_EVDEV=y
CONFIG_USB_GSPCA=m
# CONFIG_USB_M5602 is not set
# CONFIG_USB_STV06XX is not set
# CONFIG_USB_GL860 is not set
# CONFIG_USB_GSPCA_BENQ is not set
# CONFIG_USB_GSPCA_CONEX is not set
# CONFIG_USB_GSPCA_CPIA1 is not set
# CONFIG_USB_GSPCA_DTCS033 is not set
# CONFIG_USB_GSPCA_ETOMS is not set
# CONFIG_USB_GSPCA_FINEPIX is not set
# CONFIG_USB_GSPCA_JEILINJ is not set
# CONFIG_USB_GSPCA_JL2005BCD is not set
# CONFIG_USB_GSPCA_KINECT is not set
# CONFIG_USB_GSPCA_KONICA is not set
# CONFIG_USB_GSPCA_MARS is not set
# CONFIG_USB_GSPCA_MR97310A is not set
# CONFIG_USB_GSPCA_NW80X is not set
# CONFIG_USB_GSPCA_OV519 is not set
# CONFIG_USB_GSPCA_OV534 is not set
# CONFIG_USB_GSPCA_OV534_9 is not set
# CONFIG_USB_GSPCA_PAC207 is not set
# CONFIG_USB_GSPCA_PAC7302 is not set
# CONFIG_USB_GSPCA_PAC7311 is not set
# CONFIG_USB_GSPCA_SE401 is not set
# CONFIG_USB_GSPCA_SN9C2028 is not set
# CONFIG_USB_GSPCA_SN9C20X is not set
# CONFIG_USB_GSPCA_SONIXB is not set
# CONFIG_USB_GSPCA_SONIXJ is not set
# CONFIG_USB_GSPCA_SPCA500 is not set
# CONFIG_USB_GSPCA_SPCA501 is not set
# CONFIG_USB_GSPCA_SPCA505 is not set
# CONFIG_USB_GSPCA_SPCA506 is not set
# CONFIG_USB_GSPCA_SPCA508 is not set
# CONFIG_USB_GSPCA_SPCA561 is not set
# CONFIG_USB_GSPCA_SPCA1528 is not set
# CONFIG_USB_GSPCA_SQ905 is not set
# CONFIG_USB_GSPCA_SQ905C is not set
# CONFIG_USB_GSPCA_SQ930X is not set
# CONFIG_USB_GSPCA_STK014 is not set
# CONFIG_USB_GSPCA_STK1135 is not set
# CONFIG_USB_GSPCA_STV0680 is not set
# CONFIG_USB_GSPCA_SUNPLUS is not set
# CONFIG_USB_GSPCA_T613 is not set
# CONFIG_USB_GSPCA_TOPRO is not set
# CONFIG_USB_GSPCA_TOUPTEK is not set
# CONFIG_USB_GSPCA_TV8532 is not set
# CONFIG_USB_GSPCA_VC032X is not set
# CONFIG_USB_GSPCA_VICAM is not set
# CONFIG_USB_GSPCA_XIRLINK_CIT is not set
# CONFIG_USB_GSPCA_ZC3XX is not set
CONFIG_USB_PWC=m
CONFIG_USB_PWC_DEBUG=y
CONFIG_USB_PWC_INPUT_EVDEV=y
CONFIG_VIDEO_CPIA2=m
CONFIG_USB_ZR364XX=m
CONFIG_USB_STKWEBCAM=m
CONFIG_USB_S2255=m
CONFIG_VIDEO_USBTV=m
CONFIG_VIDEO_PVRUSB2=m
CONFIG_VIDEO_PVRUSB2_SYSFS=y
CONFIG_VIDEO_PVRUSB2_DVB=y
CONFIG_VIDEO_PVRUSB2_DEBUGIFC=y
CONFIG_VIDEO_HDPVR=m
CONFIG_VIDEO_USBVISION=m
CONFIG_VIDEO_STK1160_COMMON=m
CONFIG_VIDEO_STK1160=m
CONFIG_VIDEO_GO7007=m
CONFIG_VIDEO_GO7007_USB=m
CONFIG_VIDEO_GO7007_LOADER=m
CONFIG_VIDEO_GO7007_USB_S2250_BOARD=m
CONFIG_VIDEO_AU0828=m
CONFIG_VIDEO_AU0828_V4L2=y
CONFIG_VIDEO_AU0828_RC=y
CONFIG_VIDEO_CX231XX=m
CONFIG_VIDEO_CX231XX_RC=y
CONFIG_VIDEO_CX231XX_ALSA=m
CONFIG_VIDEO_CX231XX_DVB=m
CONFIG_VIDEO_TM6000=m
CONFIG_VIDEO_TM6000_ALSA=m
CONFIG_VIDEO_TM6000_DVB=m
CONFIG_DVB_USB=m
CONFIG_DVB_USB_DEBUG=y
CONFIG_DVB_USB_DIB3000MC=m
CONFIG_DVB_USB_A800=m
CONFIG_DVB_USB_DIBUSB_MB=m
CONFIG_DVB_USB_DIBUSB_MB_FAULTY=y
CONFIG_DVB_USB_DIBUSB_MC=m
CONFIG_DVB_USB_DIB0700=m
CONFIG_DVB_USB_UMT_010=m
CONFIG_DVB_USB_CXUSB=m
CONFIG_DVB_USB_M920X=m
CONFIG_DVB_USB_DIGITV=m
CONFIG_DVB_USB_VP7045=m
CONFIG_DVB_USB_VP702X=m
CONFIG_DVB_USB_GP8PSK=m
CONFIG_DVB_USB_NOVA_T_USB2=m
CONFIG_DVB_USB_TTUSB2=m
CONFIG_DVB_USB_DTT200U=m
CONFIG_DVB_USB_OPERA1=m
CONFIG_DVB_USB_AF9005=m
CONFIG_DVB_USB_AF9005_REMOTE=m
CONFIG_DVB_USB_PCTV452E=m
CONFIG_DVB_USB_DW2102=m
CONFIG_DVB_USB_CINERGY_T2=m
CONFIG_DVB_USB_DTV5100=m
CONFIG_DVB_USB_AZ6027=m
CONFIG_DVB_USB_TECHNISAT_USB2=m
CONFIG_DVB_USB_V2=m
CONFIG_DVB_USB_AF9015=m
CONFIG_DVB_USB_AF9035=m
CONFIG_DVB_USB_ANYSEE=m
CONFIG_DVB_USB_AU6610=m
CONFIG_DVB_USB_AZ6007=m
CONFIG_DVB_USB_CE6230=m
CONFIG_DVB_USB_EC168=m
CONFIG_DVB_USB_GL861=m
CONFIG_DVB_USB_LME2510=m
CONFIG_DVB_USB_MXL111SF=m
CONFIG_DVB_USB_RTL28XXU=m
CONFIG_DVB_USB_DVBSKY=m
CONFIG_DVB_USB_ZD1301=m
CONFIG_DVB_TTUSB_BUDGET=m
CONFIG_DVB_TTUSB_DEC=m
CONFIG_SMS_USB_DRV=m
CONFIG_DVB_B2C2_FLEXCOP_USB=m
CONFIG_DVB_B2C2_FLEXCOP_USB_DEBUG=y
CONFIG_DVB_AS102=m
CONFIG_VIDEO_EM28XX=m
CONFIG_VIDEO_EM28XX_V4L2=m
CONFIG_VIDEO_EM28XX_ALSA=m
CONFIG_VIDEO_EM28XX_DVB=m
CONFIG_VIDEO_EM28XX_RC=m
CONFIG_USB_AIRSPY=m
CONFIG_USB_HACKRF=m
CONFIG_USB_PULSE8_CEC=m
CONFIG_USB_RAINSHADOW_CEC=m
CONFIG_VIDEO_SOLO6X10=m
CONFIG_VIDEO_TW68=m
CONFIG_VIDEO_TW686X=m
CONFIG_VIDEO_IVTV=m
CONFIG_VIDEO_IVTV_DEPRECATED_IOCTLS=y
CONFIG_VIDEO_IVTV_ALSA=m
CONFIG_VIDEO_FB_IVTV=m
CONFIG_VIDEO_HEXIUM_GEMINI=m
CONFIG_VIDEO_HEXIUM_ORION=m
CONFIG_VIDEO_MXB=m
CONFIG_VIDEO_DT3155=m
CONFIG_VIDEO_CX18=m
CONFIG_VIDEO_CX18_ALSA=m
CONFIG_VIDEO_CX23885=m
CONFIG_MEDIA_ALTERA_CI=m
CONFIG_VIDEO_CX25821=m
CONFIG_VIDEO_CX25821_ALSA=m
CONFIG_VIDEO_CX88=m
CONFIG_VIDEO_CX88_ALSA=m
CONFIG_VIDEO_CX88_BLACKBIRD=m
CONFIG_VIDEO_CX88_DVB=m
CONFIG_VIDEO_CX88_ENABLE_VP3054=y
CONFIG_VIDEO_CX88_VP3054=m
CONFIG_VIDEO_CX88_MPEG=m
CONFIG_VIDEO_BT848=m
CONFIG_DVB_BT8XX=m
CONFIG_VIDEO_SAA7134=m
CONFIG_VIDEO_SAA7134_ALSA=m
CONFIG_VIDEO_SAA7134_RC=y
CONFIG_VIDEO_SAA7134_DVB=m
CONFIG_VIDEO_SAA7134_GO7007=m
CONFIG_VIDEO_SAA7164=m
CONFIG_DVB_AV7110_IR=y
CONFIG_DVB_AV7110=m
# CONFIG_DVB_AV7110_OSD is not set
CONFIG_DVB_BUDGET_CORE=m
CONFIG_DVB_BUDGET=m
CONFIG_DVB_BUDGET_CI=m
CONFIG_DVB_BUDGET_AV=m
CONFIG_DVB_BUDGET_PATCH=m
CONFIG_DVB_B2C2_FLEXCOP_PCI=m
CONFIG_DVB_B2C2_FLEXCOP_PCI_DEBUG=y
CONFIG_DVB_PLUTO2=m
CONFIG_DVB_DM1105=m
CONFIG_DVB_PT1=m
CONFIG_DVB_PT3=m
CONFIG_MANTIS_CORE=m
CONFIG_DVB_MANTIS=m
CONFIG_DVB_HOPPER=m
CONFIG_DVB_NGENE=m
CONFIG_DVB_DDBRIDGE=m
# CONFIG_DVB_DDBRIDGE_MSIENABLE is not set
CONFIG_DVB_SMIPCIE=m
CONFIG_VIDEO_IPU3_CIO2=m
CONFIG_V4L_PLATFORM_DRIVERS=y
CONFIG_VIDEO_CAFE_CCIC=m
CONFIG_VIDEO_CADENCE=y
CONFIG_VIDEO_CADENCE_CSI2RX=m
CONFIG_VIDEO_CADENCE_CSI2TX=m
CONFIG_SOC_CAMERA=m
CONFIG_SOC_CAMERA_PLATFORM=m
CONFIG_V4L_MEM2MEM_DRIVERS=y
CONFIG_VIDEO_MEM2MEM_DEINTERLACE=m
CONFIG_VIDEO_SH_VEU=m
CONFIG_V4L_TEST_DRIVERS=y
CONFIG_VIDEO_VIMC=m
CONFIG_VIDEO_VIVID=m
CONFIG_VIDEO_VIVID_CEC=y
CONFIG_VIDEO_VIVID_MAX_DEVS=64
CONFIG_VIDEO_VIM2M=m
CONFIG_VIDEO_VICODEC=m
CONFIG_DVB_PLATFORM_DRIVERS=y
CONFIG_CEC_PLATFORM_DRIVERS=y
CONFIG_SDR_PLATFORM_DRIVERS=y
CONFIG_RADIO_ADAPTERS=y
CONFIG_RADIO_TEA575X=m
CONFIG_RADIO_SI470X=m
CONFIG_USB_SI470X=m
CONFIG_I2C_SI470X=m
CONFIG_RADIO_SI4713=m
CONFIG_USB_SI4713=m
CONFIG_PLATFORM_SI4713=m
CONFIG_I2C_SI4713=m
CONFIG_USB_MR800=m
CONFIG_USB_DSBR=m
CONFIG_RADIO_MAXIRADIO=m
CONFIG_RADIO_SHARK=m
CONFIG_RADIO_SHARK2=m
CONFIG_USB_KEENE=m
CONFIG_USB_RAREMONO=m
CONFIG_USB_MA901=m
CONFIG_RADIO_TEA5764=m
CONFIG_RADIO_SAA7706H=m
CONFIG_RADIO_TEF6862=m
CONFIG_RADIO_WL1273=m
CONFIG_DVB_FIREDTV=m
CONFIG_DVB_FIREDTV_INPUT=y
CONFIG_MEDIA_COMMON_OPTIONS=y
CONFIG_VIDEO_CX2341X=m
CONFIG_VIDEO_TVEEPROM=m
CONFIG_CYPRESS_FIRMWARE=m
CONFIG_VIDEOBUF2_VMALLOC=m
CONFIG_VIDEOBUF2_DMA_SG=m
CONFIG_VIDEOBUF2_DVB=m
CONFIG_DVB_B2C2_FLEXCOP=m
CONFIG_DVB_B2C2_FLEXCOP_DEBUG=y
CONFIG_VIDEO_SAA7146=m
CONFIG_VIDEO_SAA7146_VV=m
CONFIG_SMS_SIANO_MDTV=m
CONFIG_SMS_SIANO_RC=y
CONFIG_VIDEO_V4L2_TPG=m
# CONFIG_MEDIA_SUBDRV_AUTOSELECT is not set
CONFIG_MEDIA_ATTACH=y
# CONFIG_VIDEO_TVAUDIO is not set
# CONFIG_VIDEO_TDA7432 is not set
# CONFIG_VIDEO_TDA9840 is not set
# CONFIG_VIDEO_TEA6415C is not set
# CONFIG_VIDEO_TEA6420 is not set
CONFIG_VIDEO_MSP3400=m
CONFIG_VIDEO_CS3308=m
CONFIG_VIDEO_CS5345=m
CONFIG_VIDEO_CS53L32A=m
# CONFIG_VIDEO_TLV320AIC23B is not set
# CONFIG_VIDEO_UDA1342 is not set
CONFIG_VIDEO_WM8775=m
CONFIG_VIDEO_WM8739=m
CONFIG_VIDEO_VP27SMPX=m
# CONFIG_VIDEO_SONY_BTF_MPX is not set
# CONFIG_VIDEO_SAA6588 is not set
# CONFIG_VIDEO_ADV7183 is not set
# CONFIG_VIDEO_ADV7842 is not set
# CONFIG_VIDEO_BT819 is not set
# CONFIG_VIDEO_BT856 is not set
# CONFIG_VIDEO_BT866 is not set
# CONFIG_VIDEO_KS0127 is not set
# CONFIG_VIDEO_ML86V7667 is not set
# CONFIG_VIDEO_AD5820 is not set
# CONFIG_VIDEO_AK7375 is not set
# CONFIG_VIDEO_DW9714 is not set
# CONFIG_VIDEO_DW9807_VCM is not set
# CONFIG_VIDEO_SAA7110 is not set
CONFIG_VIDEO_SAA711X=m
# CONFIG_VIDEO_TC358743 is not set
# CONFIG_VIDEO_TVP514X is not set
# CONFIG_VIDEO_TVP5150 is not set
# CONFIG_VIDEO_TVP7002 is not set
# CONFIG_VIDEO_TW2804 is not set
# CONFIG_VIDEO_TW9903 is not set
# CONFIG_VIDEO_TW9906 is not set
# CONFIG_VIDEO_TW9910 is not set
# CONFIG_VIDEO_VPX3220 is not set
CONFIG_VIDEO_SAA717X=m
CONFIG_VIDEO_CX25840=m
CONFIG_VIDEO_SAA7127=m
# CONFIG_VIDEO_SAA7185 is not set
# CONFIG_VIDEO_ADV7170 is not set
# CONFIG_VIDEO_ADV7175 is not set
# CONFIG_VIDEO_ADV7343 is not set
# CONFIG_VIDEO_ADV7393 is not set
# CONFIG_VIDEO_ADV7511 is not set
# CONFIG_VIDEO_AD9389B is not set
# CONFIG_VIDEO_AK881X is not set
# CONFIG_VIDEO_THS8200 is not set
# CONFIG_VIDEO_IMX258 is not set
# CONFIG_VIDEO_IMX274 is not set
# CONFIG_VIDEO_OV2640 is not set
# CONFIG_VIDEO_OV2659 is not set
# CONFIG_VIDEO_OV2680 is not set
# CONFIG_VIDEO_OV2685 is not set
# CONFIG_VIDEO_OV5647 is not set
# CONFIG_VIDEO_OV6650 is not set
# CONFIG_VIDEO_OV5670 is not set
# CONFIG_VIDEO_OV5695 is not set
# CONFIG_VIDEO_OV7251 is not set
# CONFIG_VIDEO_OV772X is not set
# CONFIG_VIDEO_OV7640 is not set
CONFIG_VIDEO_OV7670=m
# CONFIG_VIDEO_OV7740 is not set
# CONFIG_VIDEO_OV9650 is not set
# CONFIG_VIDEO_OV13858 is not set
# CONFIG_VIDEO_VS6624 is not set
# CONFIG_VIDEO_MT9M032 is not set
CONFIG_VIDEO_MT9M111=m
# CONFIG_VIDEO_MT9P031 is not set
# CONFIG_VIDEO_MT9T001 is not set
# CONFIG_VIDEO_MT9T112 is not set
# CONFIG_VIDEO_MT9V011 is not set
# CONFIG_VIDEO_MT9V032 is not set
# CONFIG_VIDEO_MT9V111 is not set
# CONFIG_VIDEO_SR030PC30 is not set
# CONFIG_VIDEO_NOON010PC30 is not set
# CONFIG_VIDEO_M5MOLS is not set
# CONFIG_VIDEO_RJ54N1 is not set
# CONFIG_VIDEO_S5K6AA is not set
# CONFIG_VIDEO_S5K6A3 is not set
# CONFIG_VIDEO_S5K4ECGX is not set
# CONFIG_VIDEO_S5K5BAF is not set
# CONFIG_VIDEO_SMIAPP is not set
# CONFIG_VIDEO_ET8EK8 is not set
# CONFIG_VIDEO_ADP1653 is not set
# CONFIG_VIDEO_LM3560 is not set
# CONFIG_VIDEO_LM3646 is not set
CONFIG_VIDEO_UPD64031A=m
CONFIG_VIDEO_UPD64083=m
# CONFIG_VIDEO_SAA6752HS is not set
# CONFIG_SDR_MAX2175 is not set
# CONFIG_VIDEO_THS7303 is not set
CONFIG_VIDEO_M52790=m
# CONFIG_VIDEO_I2C is not set
CONFIG_SOC_CAMERA_MT9M001=m
CONFIG_SOC_CAMERA_MT9M111=m
CONFIG_SOC_CAMERA_MT9T112=m
CONFIG_SOC_CAMERA_MT9V022=m
CONFIG_SOC_CAMERA_OV5642=m
CONFIG_SOC_CAMERA_OV772X=m
CONFIG_SOC_CAMERA_OV9640=m
CONFIG_SOC_CAMERA_OV9740=m
CONFIG_SOC_CAMERA_RJ54N1=m
CONFIG_SOC_CAMERA_TW9910=m
CONFIG_MEDIA_TUNER=m
CONFIG_MEDIA_TUNER_SIMPLE=m
CONFIG_MEDIA_TUNER_TDA18250=m
CONFIG_MEDIA_TUNER_TDA8290=m
CONFIG_MEDIA_TUNER_TDA827X=m
CONFIG_MEDIA_TUNER_TDA18271=m
CONFIG_MEDIA_TUNER_TDA9887=m
CONFIG_MEDIA_TUNER_TEA5761=m
CONFIG_MEDIA_TUNER_TEA5767=m
CONFIG_MEDIA_TUNER_MT20XX=m
CONFIG_MEDIA_TUNER_MT2060=m
CONFIG_MEDIA_TUNER_MT2063=m
CONFIG_MEDIA_TUNER_MT2266=m
CONFIG_MEDIA_TUNER_MT2131=m
CONFIG_MEDIA_TUNER_QT1010=m
CONFIG_MEDIA_TUNER_XC2028=m
CONFIG_MEDIA_TUNER_XC5000=m
CONFIG_MEDIA_TUNER_XC4000=m
CONFIG_MEDIA_TUNER_MXL5005S=m
CONFIG_MEDIA_TUNER_MXL5007T=m
CONFIG_MEDIA_TUNER_MC44S803=m
CONFIG_MEDIA_TUNER_MAX2165=m
CONFIG_MEDIA_TUNER_TDA18218=m
CONFIG_MEDIA_TUNER_FC0011=m
CONFIG_MEDIA_TUNER_FC0012=m
CONFIG_MEDIA_TUNER_FC0013=m
CONFIG_MEDIA_TUNER_TDA18212=m
CONFIG_MEDIA_TUNER_E4000=m
CONFIG_MEDIA_TUNER_FC2580=m
CONFIG_MEDIA_TUNER_M88RS6000T=m
CONFIG_MEDIA_TUNER_TUA9001=m
CONFIG_MEDIA_TUNER_SI2157=m
CONFIG_MEDIA_TUNER_IT913X=m
CONFIG_MEDIA_TUNER_R820T=m
CONFIG_MEDIA_TUNER_MXL301RF=m
CONFIG_MEDIA_TUNER_QM1D1C0042=m
CONFIG_MEDIA_TUNER_QM1D1B0004=m
CONFIG_DVB_STB0899=m
CONFIG_DVB_STB6100=m
CONFIG_DVB_STV090x=m
CONFIG_DVB_STV0910=m
CONFIG_DVB_STV6110x=m
CONFIG_DVB_STV6111=m
CONFIG_DVB_MXL5XX=m
CONFIG_DVB_M88DS3103=m
CONFIG_DVB_DRXK=m
CONFIG_DVB_TDA18271C2DD=m
CONFIG_DVB_SI2165=m
CONFIG_DVB_MN88472=m
CONFIG_DVB_MN88473=m
CONFIG_DVB_CX24110=m
CONFIG_DVB_CX24123=m
CONFIG_DVB_MT312=m
CONFIG_DVB_ZL10036=m
CONFIG_DVB_ZL10039=m
CONFIG_DVB_S5H1420=m
CONFIG_DVB_STV0288=m
CONFIG_DVB_STB6000=m
CONFIG_DVB_STV0299=m
CONFIG_DVB_STV6110=m
CONFIG_DVB_STV0900=m
CONFIG_DVB_TDA8083=m
CONFIG_DVB_TDA10086=m
CONFIG_DVB_TDA8261=m
CONFIG_DVB_VES1X93=m
CONFIG_DVB_TUNER_ITD1000=m
CONFIG_DVB_TUNER_CX24113=m
CONFIG_DVB_TDA826X=m
CONFIG_DVB_TUA6100=m
CONFIG_DVB_CX24116=m
CONFIG_DVB_CX24117=m
CONFIG_DVB_CX24120=m
CONFIG_DVB_SI21XX=m
CONFIG_DVB_TS2020=m
CONFIG_DVB_DS3000=m
CONFIG_DVB_MB86A16=m
CONFIG_DVB_TDA10071=m
CONFIG_DVB_SP8870=m
CONFIG_DVB_SP887X=m
CONFIG_DVB_CX22700=m
CONFIG_DVB_CX22702=m
CONFIG_DVB_S5H1432=m
CONFIG_DVB_DRXD=m
CONFIG_DVB_L64781=m
CONFIG_DVB_TDA1004X=m
CONFIG_DVB_NXT6000=m
CONFIG_DVB_MT352=m
CONFIG_DVB_ZL10353=m
CONFIG_DVB_DIB3000MB=m
CONFIG_DVB_DIB3000MC=m
CONFIG_DVB_DIB7000M=m
CONFIG_DVB_DIB7000P=m
CONFIG_DVB_DIB9000=m
CONFIG_DVB_TDA10048=m
CONFIG_DVB_AF9013=m
CONFIG_DVB_EC100=m
CONFIG_DVB_STV0367=m
CONFIG_DVB_CXD2820R=m
CONFIG_DVB_CXD2841ER=m
CONFIG_DVB_RTL2830=m
CONFIG_DVB_RTL2832=m
CONFIG_DVB_RTL2832_SDR=m
CONFIG_DVB_SI2168=m
CONFIG_DVB_AS102_FE=m
CONFIG_DVB_ZD1301_DEMOD=m
CONFIG_DVB_GP8PSK_FE=m
CONFIG_DVB_VES1820=m
CONFIG_DVB_TDA10021=m
CONFIG_DVB_TDA10023=m
CONFIG_DVB_STV0297=m
CONFIG_DVB_NXT200X=m
CONFIG_DVB_OR51211=m
CONFIG_DVB_OR51132=m
CONFIG_DVB_BCM3510=m
CONFIG_DVB_LGDT330X=m
CONFIG_DVB_LGDT3305=m
CONFIG_DVB_LGDT3306A=m
CONFIG_DVB_LG2160=m
CONFIG_DVB_S5H1409=m
CONFIG_DVB_AU8522=m
CONFIG_DVB_AU8522_DTV=m
CONFIG_DVB_AU8522_V4L=m
CONFIG_DVB_S5H1411=m
CONFIG_DVB_S921=m
CONFIG_DVB_DIB8000=m
CONFIG_DVB_MB86A20S=m
CONFIG_DVB_TC90522=m
CONFIG_DVB_MN88443X=m
CONFIG_DVB_PLL=m
CONFIG_DVB_TUNER_DIB0070=m
CONFIG_DVB_TUNER_DIB0090=m
CONFIG_DVB_DRX39XYJ=m
CONFIG_DVB_LNBH25=m
CONFIG_DVB_LNBP21=m
CONFIG_DVB_LNBP22=m
CONFIG_DVB_ISL6405=m
CONFIG_DVB_ISL6421=m
CONFIG_DVB_ISL6423=m
CONFIG_DVB_A8293=m
CONFIG_DVB_LGS8GL5=m
CONFIG_DVB_LGS8GXX=m
CONFIG_DVB_ATBM8830=m
CONFIG_DVB_TDA665x=m
CONFIG_DVB_IX2505V=m
CONFIG_DVB_M88RS2000=m
CONFIG_DVB_AF9033=m
CONFIG_DVB_HORUS3A=m
CONFIG_DVB_ASCOT2E=m
CONFIG_DVB_HELENE=m
CONFIG_DVB_CXD2099=m
CONFIG_DVB_SP2=m
# CONFIG_DVB_DUMMY_FE is not set
CONFIG_SOUND=m
CONFIG_SND=m
CONFIG_SND_TIMER=m
CONFIG_SND_PCM=m
# CONFIG_SND_OSSEMUL is not set
CONFIG_SND_PCM_TIMER=y
# CONFIG_SND_HRTIMER is not set
# CONFIG_SND_DYNAMIC_MINORS is not set
CONFIG_SND_SUPPORT_OLD_API=y
CONFIG_SND_PROC_FS=y
CONFIG_SND_VERBOSE_PROCFS=y
# CONFIG_SND_VERBOSE_PRINTK is not set
# CONFIG_SND_DEBUG is not set
CONFIG_SND_DMA_SGBUF=y
# CONFIG_SND_SEQUENCER is not set
CONFIG_SND_DRIVERS=y
# CONFIG_SND_PCSP is not set
# CONFIG_SND_DUMMY is not set
# CONFIG_SND_ALOOP is not set
# CONFIG_SND_MTPAV is not set
# CONFIG_SND_MTS64 is not set
# CONFIG_SND_SERIAL_U16550 is not set
# CONFIG_SND_MPU401 is not set
# CONFIG_SND_PORTMAN2X4 is not set
CONFIG_SND_PCI=y
# CONFIG_SND_AD1889 is not set
# CONFIG_SND_ALS300 is not set
# CONFIG_SND_ALS4000 is not set
# CONFIG_SND_ALI5451 is not set
# CONFIG_SND_ASIHPI is not set
# CONFIG_SND_ATIIXP is not set
# CONFIG_SND_ATIIXP_MODEM is not set
# CONFIG_SND_AU8810 is not set
# CONFIG_SND_AU8820 is not set
# CONFIG_SND_AU8830 is not set
# CONFIG_SND_AW2 is not set
# CONFIG_SND_AZT3328 is not set
# CONFIG_SND_BT87X is not set
# CONFIG_SND_CA0106 is not set
# CONFIG_SND_CMIPCI is not set
# CONFIG_SND_OXYGEN is not set
# CONFIG_SND_CS4281 is not set
# CONFIG_SND_CS46XX is not set
# CONFIG_SND_CTXFI is not set
# CONFIG_SND_DARLA20 is not set
# CONFIG_SND_GINA20 is not set
# CONFIG_SND_LAYLA20 is not set
# CONFIG_SND_DARLA24 is not set
# CONFIG_SND_GINA24 is not set
# CONFIG_SND_LAYLA24 is not set
# CONFIG_SND_MONA is not set
# CONFIG_SND_MIA is not set
# CONFIG_SND_ECHO3G is not set
# CONFIG_SND_INDIGO is not set
# CONFIG_SND_INDIGOIO is not set
# CONFIG_SND_INDIGODJ is not set
# CONFIG_SND_INDIGOIOX is not set
# CONFIG_SND_INDIGODJX is not set
# CONFIG_SND_EMU10K1 is not set
# CONFIG_SND_EMU10K1X is not set
# CONFIG_SND_ENS1370 is not set
# CONFIG_SND_ENS1371 is not set
# CONFIG_SND_ES1938 is not set
# CONFIG_SND_ES1968 is not set
# CONFIG_SND_FM801 is not set
# CONFIG_SND_HDSP is not set
# CONFIG_SND_HDSPM is not set
# CONFIG_SND_ICE1712 is not set
# CONFIG_SND_ICE1724 is not set
# CONFIG_SND_INTEL8X0 is not set
# CONFIG_SND_INTEL8X0M is not set
# CONFIG_SND_KORG1212 is not set
# CONFIG_SND_LOLA is not set
# CONFIG_SND_LX6464ES is not set
# CONFIG_SND_MAESTRO3 is not set
# CONFIG_SND_MIXART is not set
# CONFIG_SND_NM256 is not set
# CONFIG_SND_PCXHR is not set
# CONFIG_SND_RIPTIDE is not set
# CONFIG_SND_RME32 is not set
# CONFIG_SND_RME96 is not set
# CONFIG_SND_RME9652 is not set
# CONFIG_SND_SE6X is not set
# CONFIG_SND_SONICVIBES is not set
# CONFIG_SND_TRIDENT is not set
# CONFIG_SND_VIA82XX is not set
# CONFIG_SND_VIA82XX_MODEM is not set
# CONFIG_SND_VIRTUOSO is not set
# CONFIG_SND_VX222 is not set
# CONFIG_SND_YMFPCI is not set
# CONFIG_SND_HDA_INTEL is not set
CONFIG_SND_HDA_PREALLOC_SIZE=64
CONFIG_SND_USB=y
# CONFIG_SND_USB_AUDIO is not set
# CONFIG_SND_USB_UA101 is not set
# CONFIG_SND_USB_USX2Y is not set
# CONFIG_SND_USB_CAIAQ is not set
# CONFIG_SND_USB_US122L is not set
# CONFIG_SND_USB_6FIRE is not set
# CONFIG_SND_USB_HIFACE is not set
# CONFIG_SND_BCD2000 is not set
# CONFIG_SND_USB_POD is not set
# CONFIG_SND_USB_PODHD is not set
# CONFIG_SND_USB_TONEPORT is not set
# CONFIG_SND_USB_VARIAX is not set
CONFIG_SND_FIREWIRE=y
# CONFIG_SND_DICE is not set
# CONFIG_SND_OXFW is not set
# CONFIG_SND_ISIGHT is not set
# CONFIG_SND_FIREWORKS is not set
# CONFIG_SND_BEBOB is not set
# CONFIG_SND_FIREWIRE_DIGI00X is not set
# CONFIG_SND_FIREWIRE_TASCAM is not set
# CONFIG_SND_FIREWIRE_MOTU is not set
# CONFIG_SND_FIREFACE is not set
# CONFIG_SND_SOC is not set
CONFIG_SND_X86=y
# CONFIG_HDMI_LPE_AUDIO is not set
# CONFIG_SND_XEN_FRONTEND is not set
# CONFIG_HID_ASUS is not set
# CONFIG_HID_CORSAIR is not set
# CONFIG_HID_PRODIKEYS is not set
# CONFIG_HID_ELAN is not set
# CONFIG_HID_GOOGLE_HAMMER is not set
# CONFIG_HID_GT683R is not set
# CONFIG_HID_LED is not set
# CONFIG_HID_SONY is not set
# CONFIG_HID_THINGM is not set
# CONFIG_HID_WIIMOTE is not set
CONFIG_NEW_LEDS=y
CONFIG_LEDS_CLASS=m
# CONFIG_LEDS_CLASS_FLASH is not set
# CONFIG_LEDS_BRIGHTNESS_HW_CHANGED is not set
# CONFIG_LEDS_APU is not set
# CONFIG_LEDS_LM3530 is not set
# CONFIG_LEDS_LM3642 is not set
# CONFIG_LEDS_PCA9532 is not set
# CONFIG_LEDS_LP3944 is not set
# CONFIG_LEDS_LP5521 is not set
# CONFIG_LEDS_LP5523 is not set
# CONFIG_LEDS_LP5562 is not set
# CONFIG_LEDS_LP8501 is not set
# CONFIG_LEDS_CLEVO_MAIL is not set
# CONFIG_LEDS_PCA955X is not set
# CONFIG_LEDS_PCA963X is not set
# CONFIG_LEDS_BD2802 is not set
# CONFIG_LEDS_INTEL_SS4200 is not set
# CONFIG_LEDS_TCA6507 is not set
# CONFIG_LEDS_TLC591XX is not set
# CONFIG_LEDS_LM355x is not set
# CONFIG_LEDS_BLINKM is not set
# CONFIG_LEDS_MLXCPLD is not set
# CONFIG_LEDS_MLXREG is not set
# CONFIG_LEDS_USER is not set
# CONFIG_LEDS_NIC78BX is not set
# CONFIG_LEDS_TRIGGERS is not set
# CONFIG_ALIENWARE_WMI is not set
# CONFIG_DELL_WMI_LED is not set
# CONFIG_BT_LEDS is not set
# CONFIG_FIREWIRE_NOSY is not set
CONFIG_IR_IMON_DECODER=y
CONFIG_VIDEO_STK1160_COMMON=m
CONFIG_DVB_B2C2_FLEXCOP_USB=m
CONFIG_DVB_B2C2_FLEXCOP_USB_DEBUG=y
CONFIG_DVB_BUDGET_CORE=m
CONFIG_DVB_B2C2_FLEXCOP_PCI=m
CONFIG_DVB_B2C2_FLEXCOP_PCI_DEBUG=y
CONFIG_DVB_STV6110x=m
# CONFIG_SOUNDWIRE is not set"

# Joydev config
modules_joydev="CONFIG_MDIO_BUS_MUX=y
CONFIG_INPUT_JOYDEV=m
CONFIG_INPUT_JOYSTICK=y
# CONFIG_JOYSTICK_ANALOG is not set
# CONFIG_JOYSTICK_A3D is not set
# CONFIG_JOYSTICK_ADI is not set
# CONFIG_JOYSTICK_COBRA is not set
# CONFIG_JOYSTICK_GF2K is not set
# CONFIG_JOYSTICK_GRIP is not set
# CONFIG_JOYSTICK_GRIP_MP is not set
# CONFIG_JOYSTICK_GUILLEMOT is not set
# CONFIG_JOYSTICK_INTERACT is not set
# CONFIG_JOYSTICK_SIDEWINDER is not set
# CONFIG_JOYSTICK_TMDC is not set
# CONFIG_JOYSTICK_IFORCE is not set
# CONFIG_JOYSTICK_WARRIOR is not set
# CONFIG_JOYSTICK_MAGELLAN is not set
# CONFIG_JOYSTICK_SPACEORB is not set
# CONFIG_JOYSTICK_SPACEBALL is not set
# CONFIG_JOYSTICK_STINGER is not set
# CONFIG_JOYSTICK_TWIDJOY is not set
# CONFIG_JOYSTICK_ZHENHUA is not set
# CONFIG_JOYSTICK_DB9 is not set
# CONFIG_JOYSTICK_GAMECON is not set
# CONFIG_JOYSTICK_TURBOGRAFX is not set
# CONFIG_JOYSTICK_AS5011 is not set
# CONFIG_JOYSTICK_JOYDUMP is not set
CONFIG_JOYSTICK_XPAD=m
CONFIG_JOYSTICK_XPAD_FF=y
CONFIG_JOYSTICK_XPAD_LEDS=y
# CONFIG_JOYSTICK_WALKERA0701 is not set
# CONFIG_JOYSTICK_PSXPAD_SPI is not set
# CONFIG_JOYSTICK_PXRC is not set
CONFIG_INPUT_UINPUT=y"

## Apply changes to .config
cd ${DATA_DIR}/linux-$UNAME
echo "---Patching necessary files for 'dvb', this can take some time, please wait!---"
while read -r line
do
	line_conf=${line//# /}
	line_conf=${line_conf%%=*}
	line_conf=${line_conf%% *}
	sed -i "/$line_conf/d" ${DATA_DIR}/linux-$UNAME/.config
	echo "$line" >> ${DATA_DIR}/linux-$UNAME/.config
done <<< $modules_dvb

echo "---Patching necessary files for 'joydev', this can take some time, please wait!---"
while read -r line
do
	line_conf=${line//# /}
	line_conf=${line_conf%%=*}
	line_conf=${line_conf%% *}
	sed -i "/$line_conf/d" ${DATA_DIR}/linux-$UNAME/.config
	echo "$line" >> ${DATA_DIR}/linux-$UNAME/.config
done <<< $modules_joydev

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

## Download and install DigitalDevices drivers
echo "---Downloading DigitalDevices drivers v${NV_DRV_V}, please wait!---"
cd ${DATA_DIR}
if [ ! -d ${DATA_DIR}/dd-v${DD_DRV_V} ]; then
	mkdir ${DATA_DIR}/dd-v${DD_DRV_V}
fi
if [ ! -f ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz
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

## Decompress bzroot
echo "---Decompressing bzroot, this can take some time, please wait!---"
if [ ! -d ${DATA_DIR}/bzroot-extracted-$UNAME ]; then
	mkdir ${DATA_DIR}/bzroot-extracted-$UNAME
fi
cd ${DATA_DIR}/bzroot-extracted-$UNAME
dd if=$IMAGES_FILE_PATH/bzroot bs=512 count=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') of=${DATA_DIR}/output-$UNAME/bzroot
dd if=$IMAGES_FILE_PATH/bzroot bs=512 skip=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') | xzcat | cpio -i -d -H newc --no-absolute-filenames

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
echo "---Compiling 'libnvidia-container', , this can take some time, please wait!---"
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

## Compile 'nvidia-container-runtime'
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

### Compile 'nvidia-container-runtime'
cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src
make
cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src/nvidia-container-runtime ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin

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
	find . -type d -maxdepth 1 -not -name 'output*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
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