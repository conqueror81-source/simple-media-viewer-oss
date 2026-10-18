#!/bin/bash
# libmpv-darwin-build（v0.6.0）のうち FFmpeg だけを iOS（実機・シミュレーター）向けにビルドする。手順は README.md。
#
# 使い方: ios_build.sh <作業フォルダー>
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mkdir -p "$1" && cd "$1" && pwd)

cd "$WORK"
[ -d libmpv-darwin-build ] ||
  git clone -q --depth 1 -b v0.6.0 https://github.com/media-kit/libmpv-darwin-build.git
cd libmpv-darwin-build
git apply "$HERE/libmpv-darwin-build.patch"
for target in ios-arm64 iossimulator-arm64 iossimulator-amd64; do
  VERSION=v0.6.0-lgpl21 make "build/intermediate/ffmpeg_$target-video-default"
done
