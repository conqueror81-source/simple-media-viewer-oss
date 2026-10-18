#!/bin/bash
# libmpv-android-video-build（v1.1.7）を macOS でビルドする。手順は README.md。
#
# 使い方: android_build.sh <作業フォルダー>
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mkdir -p "$1" && cd "$1" && pwd)
NDK=~/Library/Android/sdk/ndk/27.3.13750724
[ -d "$NDK" ] || { echo "NDK 27.3.13750724 is required (sdkmanager \"ndk;27.3.13750724\")" >&2; exit 1; }

cd "$WORK"
[ -d libmpv-android-video-build ] ||
  git clone -q --depth 1 -b v1.1.7 https://github.com/media-kit/libmpv-android-video-build.git
cd libmpv-android-video-build
git apply "$HERE/libmpv-android-video-build.patch"
cd buildscripts

# 元のスクリプトは Linux で SDK を取ってくる前提。手元の SDK と、NDK に無い <triple>-nm などを用意する。
mkdir -p sdk/bin
ln -sfn ~/Library/Android/sdk sdk/android-sdk-linux
ln -sfn ~/Library/Android/sdk sdk/android-sdk-mac
curl -sL https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl -o sdk/bin/gas-preprocessor.pl
chmod +x sdk/bin/gas-preprocessor.pl
for triple in aarch64-linux-android arm-linux-androideabi i686-linux-android x86_64-linux-android; do
  for tool in nm strip ar ranlib; do
    ln -sf "$(echo "$NDK"/toolchains/llvm/prebuilt/*/bin/llvm-$tool)" "sdk/bin/$triple-$tool"
  done
done

./include/download-deps.sh
./patch.sh
cp flavors/default.sh scripts/ffmpeg.sh
for arch in arm64 armv7l x86_64 x86; do
  ./build.sh --arch $arch
done
