# Unraid Kernel Helper
With this container you can build your own customized Unraid Kernel.

By default it will create the Kernel/Firmware/Modules/Rootfilesystem with the nVidia drivers and also DVB drivers (currently DigitalDevices and LibreElec built in).

**nVidia Driver installation:** If you build the container with the nVidia drivers please make sure that no other process is using the graphics card otherwise the installation will fail and no nVidia drivers will be installed.

**ATTENTION:** Please read the discription of the variables carefully! If you started the container don't interrupt the build process, the container will automatically shut down if everything is finished. I recommend to open the log window, the build itself can take very long depending on your hardware but should be done in ~30minutes).

THIS CONTAINER WILL NOT CHANGE ANYTHING TO YOUR EXISTING INSTALLATION OR ON YOUR USB KEY/DRIVE, YOU HAVE TO MANUALLY PUT THE CREATED FILES IN THE OUTPUT FOLDER TO YOUR USB KEY/DRIVE.

**UPDATE:** If a new Update of Unraid is released you have to change the Repository to the corresponding build number (I will create the appropriate container as soon as possible) eg: 'ich777/unraid-kernel-helper:6.8.3'.

**ATTENTION:** PLEASE BACKUP YOUR EXISTING USB DRIVE FILES TO YOUR LOCAL COMPUTER IN CASE SOMETHING GOES WRONG!
I AM NOT RESPONSIBLE IF YOU BREAK YOUR SERVER OR SOMETHING OTHER WITH THIS CONTAINER, THIS CONTAINER IS THERE TO HELP YOU EASILY BUILD A NEW IMAGE AND UNDERSTAND HOW THIS IS WORKING.

**Forum Notice:** When something isn't working with your server and you make a post on the forum always note that you use a Kernel built by this container!

**CUSTOM_MODE:**
This is only for Advanced users!
In this mode the container will stop right at the beginning and will copy over the build script and the dependencies to build the kernel modules for DVB and joydev in the main directory (I highly recommend using this mode for changing things in the build script like adding patches or other modules to build, connect to the console of the container with: 'docker exec -ti NAMEOFYOURCONTAINER /bin/bash' and then go to the /usr/src directory, also the build script is executable).

>Note: You can use the nVidia & DVB Plugin from linuxserver.io to check if your driver is installed correctly (keep in mind that some things will display wrong and or not showing up like the driver version in the nVidia Plugin - but you will see the installed grapics cards and also in the DVB plugin it will show that no kernel driver is installed but you will see your installed cards - this is simply becaus i don't know how their plugins work).

## Env params
| Name | Value | Example |
| --- | --- | --- |
| DATA_DIR | Main Data Path | /usr/src |
| CPU_COUNT | Compile CPU Count (assign as many cores of your CPU you want or set to 'all' if you want to use all) | all |
| DD_DRV_V | DigitalDevices Driver Version (set to 'latest' and the container tries to get the latest version from github or enter you preferred version number eg: 0.9.37) | latest |
| NV_DRV_V | nVidia Driver Version (set to 'latest' and the container tries to get the latest version or enter you preferred version number eg: 440.82) | latest |
| SECCOMP_V | Seccomp Version (set to 'latest' and the container tries to get the latest version from Github or enter you preferred version number eg: 2.4.3) | latest |
| LIBNVIDIA_CONTAINER_V | libnvidia-container Version (set to 'latest' and the container tries to get the latest version or enter you preferred version number eg: 1.1.1) | latest |
| LE_DRV_V | LibreELEC Driver Version (set to 'latest' and the container tries to get the latest version or enter you preferred version number eg: 1.4.0) | latest |
| BUILD_NVIDIA | Set to 'true' to build the images with with nVidia drivers (otherwise leave empty) | true |
| BUILD_DVB | Set to 'true' to build the images with with DVB drivers (otherwise leave empty) | /true |
| IMAGES_FILE_PATH | This is the default location where your Stock Unraid bzroot, bzimage, bzmodules & bzfirmware inside your container is located (only change if you are know what you are doing!) | /usr/src/stock |
| NVIDIA_CONTAINER_RUNTIME_V | libnvidia-container Version (as time of writing please let it set to 3.1.4 since the build script have to be update to work with newer versions) | 3.1.4 |
| CREATE_BACKUP | Create Backup of your existing files to data directory | true |
| CLEANUP | Available options are: 'full', 'moderate', 'none' | moderate |
| CUSTOM_MODE | Only for advanced users, leave empty when you don't know what it is | |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| UMASK | User file permission mask for newly created files | 000 |
| DATA_PERM | Data permissions for main storage folder | 770 |

## Run example
```
docker run --name Unraid-Kernel-Helper -d \
    --env 'BUILD_NVIDIA=true' \
    --env 'BUILD_DVB=true' \
    --env 'NV_DRV_V=latest' \
    --env 'DD_DRV_V=latest' \
    --env 'LE_DRV_V=latest' \
    --env 'SECCOMP_V=latest' \
    --env 'LIBNVIDIA_CONTAINER_V=latest' \
    --env 'CPU_COUNT=all' \
    --env 'CREATE_BACKUP=true' \
    --env 'CLEANUP=moderate' \
    --env 'UID=99' \
    --env 'GID=100' \
    --env 'UMASK=000' \
    --env 'DATA_PERM=770' \
    --privileged=true \
    --volume /mnt/cache/appdata/kernel:/usr/src \
    --volume /usr/src:/host/usr/src \
    --volume /boot:/host/boot \
    --volume /usr/src:/host/usr/src \
    ich777/unraid-kernel-helper:6.8.3
```

If you don't use Unraid you should definitely try it!

#### Support Thread: https://forums.unraid.net/topic/92865-support-ich777-nvidiadvb-kernel-helper-docker/