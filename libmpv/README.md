# libmpv（FFmpeg を LGPL 2.1 にしたもの）

media_kit が使う libmpv の FFmpeg は、元のビルドでは Mbed TLS（Apache 2.0）と組み合わせるため `--enable-version3` が付いており LGPL 3 になっている。
アプリの動画は端末内の中継（`http://127.0.0.1`）を読むだけで TLS は要らないので、Mbed TLS を外して LGPL 2.1 でビルドし直したものを使う（理由は `docs/LICENSES.md`）。

- iOS：`third_party/media_kit_libs_ios_video/ios/libmpv-xcframeworks-lgpl21.tar.gz`
- Android：`third_party/media_kit_libs_android_video/android/libs/default-<ABI>.jar`
- どちらもルートの `pubspec.yaml` の `dependency_overrides` で元の `media_kit_libs_ios_video`・`media_kit_libs_android_video` と差し替えている。パッケージの中身は元の版（1.1.4・1.3.8）のコピーで、ダウンロードする代わりに同梱のファイルを使うように変えただけ

## 元にしたもの

- iOS：[libmpv-darwin-build](https://github.com/media-kit/libmpv-darwin-build) v0.6.0（FFmpeg 6.0）
- Android：[libmpv-android-video-build](https://github.com/media-kit/libmpv-android-video-build) v1.1.7（FFmpeg 6.0、mpv 78d43740）

## 変更点

共通（FFmpeg の configure）：

- `--enable-mbedtls`・`--enable-version3` を外す → `libavutil license: LGPL version 2.1 or later`
- TLS が要るプロトコル（`https`・`tls`・`rtmps`・`rtmpts`）を外す
- デコーダー・デマクサーなどは元のまま

iOS（`libmpv-darwin-build.patch`）：

- **2026-10-18（案 B）**：H.264・HEVC・AAC のソフトウェアデコーダーと、それらを一緒に入れてしまう VideoToolbox の H.264・HEVC の hwaccel を外した。AAC は AudioToolbox（`aac_at`）。DTS は既定でコアだけをデコードする（`dcadec.c` の既定値を変える）。AVPlayer 用の HLS（fMP4）への詰め替えのため、mp4・mov の muxer、FLAC の encoder、TrueHD・MLP・PGS 字幕の decoder、`extract_extradata`・`h264_mp4toannexb`・`hevc_mp4toannexb` の bsf を追加
- Makefile：FFmpeg・libs-arch の Mbed TLS への依存を外す
- **2026-10-23**：特許の状況が確認できない DTS（dca）・TrueHD・MLP・WMA（wmav1/wmav2/wmapro/wmavoice/wmalossless）・ATRAC（atrac1/3/3al/3p/3pal/9）・VC-1（vc1・vc1image・wmv3・wmv3image）のデコーダーも外した（`--disable-decoder=`）。アプリはこれらを「再生できない」と表示する
- 今の Xcode（26 以降）・meson（1.3 以降）で通すための修正：`find_program('pkg-config')`、ホスト用 pkg-config に `-Wno-int-conversion`、シミュレーター arm64 を `-mios-simulator-version-min`
- 全体のビルドは今の Xcode では HarfBuzz・uchardet が通らないので、FFmpeg だけビルドし、元の xcframework 一式の FFmpeg の 6 つ（Avcodec・Avfilter・Avformat・Avutil・Swresample・Swscale）を差し替え、Mbed TLS の 3 つを除く（`ios_package.sh`）。FFmpeg の版（6.0）と各ライブラリの版は元と同じなので、mpv などはそのまま使える

Android（`libmpv-android-video-build.patch`）：

- **2026-10-18（案 B）**：FFmpeg を 7.1.1 に上げ、H.264・HEVC・AAC のソフトウェアデコーダーを外して MediaCodec 版（`h264_mediacodec`・`hevc_mediacodec`・`aac_mediacodec`。AAC は 7.1 から）にした。DTS は既定でコアだけをデコードする（`dca_core_only.patch`）。mpv（78d43740）は FFmpeg 7 で通すための修正（`mpv_ffmpeg7.patch`）。元の FFmpeg のパッチ（DASH・HLS 用）は 7.1 に当たらず、使わないので外した。アプリ側は mpv のデコーダーに MediaCodec を指定する（`vd=lavc:h264_mediacodec,lavc:hevc_mediacodec,`、hwdec は使わない）

- **2026-10-23**：iOS と同じく DTS・TrueHD・MLP・WMA・ATRAC・VC-1 のデコーダーを外した（`wmv*` は wmv1・wmv2 だけに）。FFmpeg 7.1 に当たらない元の DASH・HLS 用のパッチ（`dash_base_url_escape.patch`・`hls_mp4_seek.patch`）を消す変更がパッチに入っていなかったので加えた
- `depinfo.sh`：FFmpeg の依存から mbedtls を外す。NDK を 27.3.13750724（元の bundle スクリプトが strip に使っている版）に
- `build.sh`：`sudo` を使わない。meson の `prefix`・`libdir` を指定（Homebrew の meson は既定が `/opt/homebrew` になるため）
- FFmpeg は libmpv.so に静的に入っているので mpv ごとビルドし直す。`libmediakitandroidhelper.so` は元の jar のものを使う（`android_package.sh`）

## 作り直す手順（macOS）

```sh
brew install go meson ninja cmake automake autoconf libtool coreutils gnu-sed wget nasm pkgconf
sdkmanager "ndk;27.3.13750724"

# iOS
tools/libmpv/ios_build.sh /tmp/libmpv
tools/libmpv/ios_package.sh /tmp/libmpv/libmpv-darwin-build third_party/media_kit_libs_ios_video/ios/libmpv-xcframeworks-lgpl21.tar.gz

# Android
tools/libmpv/android_build.sh /tmp/libmpv
tools/libmpv/android_package.sh /tmp/libmpv/libmpv-android-video-build third_party/media_kit_libs_android_video/android/libs
```

## LGPL のソースの提供

アプリの配布（ストアでの販売を含む）には、LGPL のライブラリ（FFmpeg・mpv など）のソースと、それをビルドし直す手段を利用者が入手できるようにする必要がある。
元のソースの入手先と、このフォルダーの変更点（パッチ・スクリプト）を、利用者がアクセスできる場所（公開のリポジトリなど）に置き、アプリのライセンス画面（`assets/licenses/notice.txt`）からたどれるようにする。
