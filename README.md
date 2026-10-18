# Simple Media Viewer — オープンソースのソースコード

iOS・Android 向けのアプリ「Simple Media Viewer」が同梱している、GNU LGPL のライブラリ（mpv・FFmpeg など）の対応するソースコードと、アプリのために加えた変更を公開するリポジトリです。アプリ本体のソースコードは含みません。

- サポート・プライバシーポリシー・利用規約：https://conqueror81-source.github.io/simple-media-viewer-oss/
- English summary: This repository provides the corresponding source code and the modifications (patches and build scripts) of the LGPL libraries (mpv, FFmpeg, etc.) bundled with the Simple Media Viewer app. The app's own source code is not included.

## 同梱しているライブラリ

- mpv（libmpv）：LGPL 2.1 以降（`-Dgpl=false`）
- FFmpeg（libavcodec ほか）：LGPL 2.1 以降（GPL の部品・`--enable-version3` を含まない）
- libsmb2：LGPL 2.1 以降（[dart_smb2](https://github.com/ales-drnz/dart_smb2) v0.1.3 に同梱の [libsmb2](https://github.com/sahlberg/libsmb2) v6.1.0。変更なし）
- FriBidi：LGPL 2.1 以降（変更なし）
- uchardet：MPL 1.1 / GPL 2 / LGPL 2.1 から LGPL 2.1 を選択（変更なし）

## 元にしたもの

- iOS：[media-kit/libmpv-darwin-build](https://github.com/media-kit/libmpv-darwin-build) v0.6.0（FFmpeg 6.0）
- Android：[media-kit/libmpv-android-video-build](https://github.com/media-kit/libmpv-android-video-build) v1.1.7（FFmpeg は 7.1.1 に変更、mpv 78d43740）

ソース一式（元のビルドスクリプトと、ビルドで取り込む各ライブラリのソース）の tar は、このリポジトリの Releases に、アプリの版ごとに添付しています。

## 変更点の要約

`libmpv/` に、パッチ（`*.patch`）とビルド・まとめ直しのスクリプトがあります。詳細は `libmpv/README.md`。

- 共通：FFmpeg の configure から `--enable-mbedtls`・`--enable-version3` と TLS のプロトコル（https・tls・rtmps・rtmpts）を外し、LGPL 2.1 にする
- 共通：H.264・HEVC・AAC のソフトウェアデコーダーを外す（iOS は AVPlayer・AudioToolbox、Android は MediaCodec を使う）。DTS は既定でコアだけをデコードする
- iOS：今の Xcode・meson でビルドを通すための修正。PGS 字幕のデコーダーを追加
- Android：FFmpeg 7.1.1 に上げ、mpv を FFmpeg 7 で通す修正。avi の H.264 のために、空の映像パケットを捨てる処理と、POC から pts を計算する処理（`demux/h264_poc.h`）を mpv に追加

## ビルドし直す（ライブラリを差し替える）

手順は `libmpv/README.md` の「作り直す手順」。macOS（Xcode・Android NDK 27.3.13750724）でビルドします。

- iOS：出来た FFmpeg の xcframework を、アプリの `Frameworks/` の同じ名前の framework と差し替えます
- Android：出来た `libmpv.so` を、APK の `lib/<ABI>/` の同じ名前のファイルと差し替え、署名し直します

差し替えに必要な情報が他にある場合は、サポートのページの連絡先までお問い合わせください。

## ライセンス

このリポジトリのパッチ・スクリプトは、それぞれが変更する元のソフトウェアと同じライセンス（mpv・FFmpeg への変更は LGPL 2.1 以降）で提供します。`docs/`（Web ページ）は Simple Media Viewer の文書です。
