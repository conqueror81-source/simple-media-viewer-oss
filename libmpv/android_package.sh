#!/bin/bash
# libmpv-android-video-build の jar の libmpv.so を、FFmpeg を LGPL 2.1 でビルドし直したものに差し替える。
# libmediakitandroidhelper.so は元の jar のものをそのまま使う。手順は README.md。
#
# 使い方: android_package.sh <libmpv-android-video-build のフォルダー> <jar を置くフォルダー>
set -euo pipefail

SRC=$(cd "$1" && pwd)
OUT=$(mkdir -p "$2" && cd "$2" && pwd)
VERSION=v1.1.7
STRIP=$(echo ~/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/*/bin/llvm-strip)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for pair in arm64-v8a:83df25b61193af8fa815e373143ac9af armeabi-v7a:22e21526fefc0a2b8f17adbec9f57590 \
  x86_64:6fa26bf0459b11f1c0b0dbc29e5b940d x86:0d742b756dc9d1fcd84ea271d8b68f32; do
  abi=${pair%%:*}
  md5=${pair##*:}
  jar=default-$abi.jar
  curl -sL "https://github.com/media-kit/libmpv-android-video-build/releases/download/$VERSION/$jar" -o "$WORK/$jar"
  [ "$(md5 -q "$WORK/$jar")" == "$md5" ] || { echo "md5 mismatch: $jar" >&2; exit 1; }

  rm -rf "$WORK/lib"
  unzip -q "$WORK/$jar" -d "$WORK"
  so=$SRC/buildscripts/prefix/$abi/lib/libmpv.so
  if strings "$so" | grep -q "LGPL version 3"; then
    echo "FFmpeg is still LGPL 3: $so" >&2
    exit 1
  fi
  "$STRIP" --strip-all -o "$WORK/lib/$abi/libmpv.so" "$so"
  rm -f "$OUT/$jar"
  (cd "$WORK" && zip -q -X -r "$OUT/$jar" "lib/$abi")
  echo "$OUT/$jar"
done
