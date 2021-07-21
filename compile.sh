#!/usr/bin/env bash
echo "Downloading few Dependecies . . ."
git clone --depth=1 https://github.com/xyz-prjkt/xRageTC-clang.git xRage
git clone --depth=1 https://github.com/Plankton00/Magazine-Kernel-X00T.git Magazine-HMP

# Main
KERNEL_ROOTDIR=$(pwd)/Magazine-HMP # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG=Magazine_defconfig # IMPORTANT ! Declare your kernel source defconfig file here.
CLANG_ROOTDIR=$(pwd)/xRage # IMPORTANT! Put your clang directory here.
export KBUILD_BUILD_USER=StarWars # Change with your own name or else.
export KBUILD_BUILD_HOST=Plankton86 # Change with your own hostname.
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/Magazine-HMP/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date "+%B %-d, %Y")
ZIP_DATE=$(date +"%Y%m%d-%H%M")
START=$(date +"%s")
BUILD_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo xKernelCompiler
echo version : rev1.5 - gaspoll
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo CLANG_VERSION = $(${CLANG_ROOTDIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot${bot_token}/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="${chat_id}" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}

# Post Main Information
tg_post_msg "<b>🔨 Building Kernel Started!</b>%0A<b>Builder Name: </b><code>${KBUILD_BUILD_USER}</code>%0A<b>Builder Host: </b><code>${KBUILD_BUILD_HOST}</code>%0A<b>Build For: </b><code>ZenFone Max Pro M1</code>%0A<b>Build Date: </b><code>$BUILD_DATE</code>%0A<b>Build started on: </b><code>Drone CI</code>%0A<b>Clang Rootdir : </b><code>${CLANG_ROOTDIR}</code>%0A<b>Kernel Rootdir : </b><code>${KERNEL_ROOTDIR}</code>%0A<b>Compiler Info:</b>%0A<code>${KBUILD_COMPILER_STRING}</code>%0A%0A1:00 ●━━━━━━─────── 2:00 ⇆ㅤㅤㅤ ㅤ◁ㅤㅤ❚❚ㅤㅤ▷ㅤㅤㅤㅤ↻"

# Compile
compile(){
tg_post_msg "<b>xKernelCompiler:</b><code>Compilation has started"
  cd ${KERNEL_ROOTDIR}
  make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
  make -j$(nproc) ARCH=arm64 O=out \
  	CC=${CLANG_ROOTDIR}/bin/clang \
	AR=${CLANG_ROOTDIR}/bin/llvm-ar \
	NM=${CLANG_ROOTDIR}/bin/llvm-nm \
	OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
	OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
	STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
	CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
        git clone --depth=1 https://github.com/Plankton00/AnyKernel3.git AnyKernel
	cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}


# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot${bot_token}/sendDocument" \
        -F chat_id="${chat_id}" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [HMP]Magazine-Kernel-X00T-${ZIP_DATE}.zip *
    cd ..
}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
