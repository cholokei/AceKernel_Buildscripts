#!/bin/bash

###############################################################################
# Ace Kernel build script by Cholokei - leesl0416@naver.com                   #
###############################################################################

DEVICE="$1"
#THREADS="$2"
TOOLCHAIN="$2"

# Colorize and add text parameters
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
ylw=$(tput setaf 3)             #  yellow
blu=$(tput setaf 4)             #  blue
ppl=$(tput setaf 5)             #  purple
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             #  Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldylw=${txtbld}$(tput setaf 3) #  yellow
bldblu=${txtbld}$(tput setaf 4) #  blue
bldppl=${txtbld}$(tput setaf 5) #  purple
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             #  Reset

# system compiler
if [ "$TOOLCHAIN" == "google-gcc" ]
then
	export PATH=$HOME/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin:$PATH
elif [ "$TOOLCHAIN" == "linaro-gcc" ]
then
	export PATH=$HOME/linaro-toolchain/android-toolchain-eabi/bin:$PATH
else
	export PATH=$HOME/linaro-toolchain/android-toolchain-eabi/bin:$PATH
fi

#export PATH=$HOME/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin:$PATH
#export PATH=$HOME/linaro-toolchain/android-toolchain-eabi/bin:$PATH

export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-

# number of cpus
#export NUMBEROFCPUS=128

NUMBEROFCPUS=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
THREADS=$(expr ${NUMBEROFCPUS} \* 64)

# location
export KERNELDIR=`readlink -f .`
export OUTDIR=`readlink -f ..`
export READY_KERNEL="READY_KERNEL"
export MODULES=`find -name *.ko`

export BUILD_DATE=$(date +"%Y%m%d")
export BUILD_TIME=$(date +"%H%M")

KERNEL_VERSION=$(cat ${KERNELDIR}/Makefile | grep '^VERSION = *' | sed 's/VERSION = //g')
KERNEL_PATCHLEVEL=$(cat ${KERNELDIR}/Makefile | grep '^PATCHLEVEL = *' | sed 's/PATCHLEVEL = //g')
KERNEL_SUBLEVEL=$(cat ${KERNELDIR}/Makefile | grep '^SUBLEVEL = *' | sed 's/SUBLEVEL = //g')

if [ "$DEVICE" == "dalikt" ]
then
	MODEL=SHV-E120K
	KERNEL_CMDLINE="androidboot.hardware=qcom kgsl.mmutype=gpummu vmalloc=400M usb_id_pin_rework=true"
	KERNEL_BASE=0x48000000
	KERNEL_PAGESIZE=2048
	KERNEL_RAMDISKADDR=0x49400000
elif [ "$DEVICE" == "dalilgt" ]
then
	MODEL=SHV-E120L
elif [ "$DEVICE" == "daliskt" ]
then
	MODEL=SHV-E120S
elif [ "$DEVICE" == "quincykt" ]
then
	MODEL=SHV-E160K
elif [ "$DEVICE" == "quincylgt" ]
then
	MODEL=SHV-E160L
elif [ "$DEVICE" == "quincyskt" ]
then
	MODEL=SHV-E160S
elif [ "$DEVICE" == "celoxskt" ]
then
	MODEL=SHV-E110S
else
	echo -e "${bldred}Can't find device code name ${txtrst}"
	exit 0
fi

KERNEL_CONFIG="ace_"$DEVICE"_defconfig"

# remove previous zImage files
cd ${KERNELDIR}
if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	rm ${KERNELDIR}/arch/arm/boot/zImage
fi;

# remove all old modules before compile
cd ${KERNELDIR}
for i in $MODULES; do
	rm -f $i
done;

echo -e "${bldred}Removed old zImage and modules ${txtrst}"

# remove old defconfig
if [ -e ${KERNELDIR}/.config ]; then
	rm ${KERNELDIR}/.config
	echo -e "${bldred}Removed old configuration ${txtrst}"
fi;

# clean
#nice -n 10 make mrproper

# get time of startup
time1=$(date +%s.%N)

echo -e ">>> ${bldgrn}${KERNEL_CONFIG} ${txtrst}"
make ${KERNEL_CONFIG}

echo -e "${bldgrn}Starting Ace Kernel compilation for "$MODEL"("$DEVICE") ${txtrst}"
echo -e "${bldylw}Linux Kernel "$KERNEL_VERSION"."$KERNEL_PATCHLEVEL"."$KERNEL_SUBLEVEL" ${txtrst}"
nice -n 10 make -j"$THREADS"

if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	echo -e "${bldgrn}Ace Kernel for "$MODEL"("$DEVICE") compiled sucessfully! ${txtrst}"
	if [ -e ${OUTDIR}/${READY_KERNEL} ]; then
	cd ${OUTDIR}/${READY_KERNEL}
	else
	cd ${OUTDIR}; mkdir ${READY_KERNEL}
	cd ${OUTDIR}/${READY_KERNEL}
	fi;
	
	mkdir "$MODEL"_${BUILD_DATE}-${BUILD_TIME}
	cd ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}
	cp ${KERNELDIR}/arch/arm/boot/zImage ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}/zImage
	#cp ${KERNELDIR}/${MODULES} ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}
	cd ${KERNELDIR}; find -name "*.ko" -exec cp {} ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME} \;
	cp ${KERNELDIR}/.config ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}/config
	echo -e "${bldylw}Now you can find zImage, modules and config in ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME} ${txtrst}"
else
	echo -e "${bldred}Failed to compile kernel! ${txtrst}"
fi;

if [ -e ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}/zImage -a -e ${OUTDIR}/${READY_KERNEL}/"$DEVICE"_ramdisk.gz -a -e ${OUTDIR}/${READY_KERNEL}/mkbootimg ]; then
	cp ${OUTDIR}/${READY_KERNEL}/"$DEVICE"_ramdisk.gz ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}/ramdisk.gz
	cp ${OUTDIR}/${READY_KERNEL}/mkbootimg ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}/mkbootimg
	cd ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME}
	chmod 777 mkbootimg
	./mkbootimg --kernel zImage --ramdisk ramdisk.gz --cmdline "$KERNEL_CMDLINE" --base "$KERNEL_BASE" --pagesize "$KERNEL_PAGESIZE" --ramdiskaddr "$KERNEL_RAMDISKADDR" -o boot.img
	rm -rf mkbootimg
	echo -e "${bldylw}Now you can find boot.img to flash in ${OUTDIR}/${READY_KERNEL}/"$MODEL"_${BUILD_DATE}-${BUILD_TIME} ${txtrst}"
else
	exit 0
fi;

time2=$(date +%s.%N)

echo "${bldcya}Total time elapsed: ${txtrst}${bldcya}$(echo "($time2 - $time1) / 60"|bc ) minutes ($(echo "$time2 - $time1"|bc ) seconds) ${txtrst}"
