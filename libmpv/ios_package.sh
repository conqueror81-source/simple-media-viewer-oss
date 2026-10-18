#!/bin/bash
# libmpv-darwin-build の xcframework のうち、FFmpeg の 6 つだけを LGPL 2.1 でビルドし直したものに差し替え、
# Mbed TLS の xcframework を除いた一式を tar.gz にする。手順は README.md。
#
# 使い方: ios_package.sh <libmpv-darwin-build のフォルダー> <出力する tar.gz>
set -euo pipefail

SRC=$(cd "$1" && pwd)
OUT=$2
VERSION=v0.6.0
SHA256=a95bc18508af26136b8a408341c05b5585d644ec013f00ac07db09d2e28d36ae
URL=https://github.com/media-kit/libmpv-darwin-build/releases/download/$VERSION/libmpv-xcframeworks_${VERSION}_ios-universal-video-default.tar.gz

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

curl -sL "$URL" -o "$WORK/upstream.tar.gz"
shasum -a 256 -c <<< "$SHA256  $WORK/upstream.tar.gz"
mkdir -p "$WORK/Frameworks"
tar -xzf "$WORK/upstream.tar.gz" --strip-components 1 -C "$WORK/Frameworks"
rm -rf "$WORK/Frameworks"/Mbed*.xcframework

INTER=$SRC/build/intermediate
# ビルドしたときの絶対パスの依存を、xcframework の中の名前（@rpath/<名前>.framework/<名前>）に付け替える。
relink() {
  local bin=$1 name=$2
  install_name_tool -id "@rpath/$name.framework/$name" "$bin"
  otool -L "$bin" | tail -n +2 | awk '{print $1}' | while read -r dep; do
    case "$dep" in
      "$INTER"/*)
        local base=${dep##*/} target
        case "$base" in
          libavcodec.*) target=Avcodec ;;
          libavfilter.*) target=Avfilter ;;
          libavformat.*) target=Avformat ;;
          libavutil.*) target=Avutil ;;
          libswresample.*) target=Swresample ;;
          libswscale.*) target=Swscale ;;
          libxml2.*) target=Xml2 ;;
          libdav1d.*) target=Dav1d ;;
          *) echo "unknown dependency: $dep" >&2; exit 1 ;;
        esac
        install_name_tool -change "$dep" "@rpath/$target.framework/$target" "$bin"
        ;;
    esac
  done
  if otool -L "$bin" | grep -q "$INTER"; then
    echo "absolute path remains in $bin" >&2
    exit 1
  fi
  codesign -f -s - "$bin" 2> /dev/null
}

for pair in avcodec:Avcodec avfilter:Avfilter avformat:Avformat avutil:Avutil swresample:Swresample swscale:Swscale; do
  lib=${pair%%:*}
  name=${pair##*:}
  xc=$WORK/Frameworks/$name.xcframework

  device=$xc/ios-arm64/$name.framework/$name
  cp "$(echo "$INTER"/ffmpeg_ios-arm64-video-default/lib/lib$lib.*.*.*.dylib)" "$device"
  relink "$device" "$name"

  simulator=$xc/ios-arm64_x86_64-simulator/$name.framework/$name
  lipo -create \
    "$(echo "$INTER"/ffmpeg_iossimulator-arm64-video-default/lib/lib$lib.*.*.*.dylib)" \
    "$(echo "$INTER"/ffmpeg_iossimulator-amd64-video-default/lib/lib$lib.*.*.*.dylib)" \
    -output "$simulator"
  relink "$simulator" "$name"
done

if strings "$WORK/Frameworks/Avutil.xcframework/ios-arm64/Avutil.framework/Avutil" | grep -q "LGPL version 3"; then
  echo "FFmpeg is still LGPL 3" >&2
  exit 1
fi

mkdir -p "$WORK/out/libmpv-xcframeworks"
mv "$WORK/Frameworks"/*.xcframework "$WORK/out/libmpv-xcframeworks/"
tar -czf "$OUT" -C "$WORK/out" libmpv-xcframeworks
echo "$OUT"
