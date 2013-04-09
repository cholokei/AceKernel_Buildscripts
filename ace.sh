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

KERNEL_VERSION=$(cat ${KERNELDIR}/Makefile | grep '^VERSION = *' | sed 's/VERSION = //g')
KERNEL_PATCHLEVEL=$(cat ${KERNELDIR}/Makefile | grep '^PATCHLEVEL = *' | sed 's/PATCHLEVEL = //g')
KERNEL_SUBLEVEL=$(cat ${KERNELDIR}/Makefile | grep '^SUBLEVEL = *' | sed 's/SUBLEVEL = //g')

if [ "$DEVICE" == "dalikt" ]
then
	MODEL=SHV-E120K
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

make ${KERNEL_CONFIG}
echo -e

echo -e "${bldgrn}Starting Ace Kernel compilation for "$MODEL"("$DEVICE") ${txtrst}"
echo -e "${bldylw}Linux Kernel "$KERNEL_VERSION"."$KERNEL_PATCHLEVEL"."$KERNEL_SUBLEVEL" ${txtrst}"
nice -n 10 make -j"$THREADS"
#if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
#	res2=$(date +%s.%N)

