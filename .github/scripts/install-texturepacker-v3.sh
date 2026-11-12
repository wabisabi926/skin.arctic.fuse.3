#!/usr/bin/env bash
# Build Kodi 22 (Piers) TexturePacker v3 from upstream source at a pinned commit.
#
# Ubuntu noble ships kodi-tools-texturepacker 2:20.5 (Nexus), which writes XBT v2.
# Kodi 22's own TexturePacker reports "Texture Packer Version 3" and writes XBTF3.
# Both release.yml and textures.yml call this script so only one packer is used.
#
# Override the pinned ref with the KODI_SHA environment variable if needed.

set -euo pipefail

KODI_SHA="${KODI_SHA:-bd9ecad99c41f54087dc9341b32b335e17cc75ef}"
TP_BIN="/usr/local/bin/kodi-TexturePacker-v3"
KODI_SRC="${RUNNER_TEMP:-/tmp}/xbmc-src"
TP_BUILD="${RUNNER_TEMP:-/tmp}/texturepacker-build"

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  build-essential cmake git \
  liblzo2-dev libpng-dev libgif-dev libjpeg-dev

rm -rf "${KODI_SRC}" "${TP_BUILD}"
git init -q "${KODI_SRC}"
git -C "${KODI_SRC}" remote add origin https://github.com/xbmc/xbmc.git
git -C "${KODI_SRC}" fetch -q --depth 1 origin "${KODI_SHA}"
git -C "${KODI_SRC}" sparse-checkout init --cone
git -C "${KODI_SRC}" sparse-checkout set xbmc tools/depends/native/TexturePacker
git -C "${KODI_SRC}" checkout -q FETCH_HEAD

TP_SRC="${KODI_SRC}/tools/depends/native/TexturePacker/src"
# Kodi 的构建系统会注入 ARCH_DEFINES；独立编译时必须显式给 TARGET_POSIX，
# 否则 cmdlineargs.h 会走 Windows 分支去 include <windows.h>。
cmake -S "${TP_SRC}" -B "${TP_BUILD}" \
  -DKODI_SOURCE_DIR="${KODI_SRC}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-DTARGET_POSIX"
cmake --build "${TP_BUILD}" --parallel 2
sudo install -m 0755 "${TP_BUILD}/TexturePacker" "${TP_BIN}"

# -help returns 1 by design; capture the banner and assert it is v3.
"${TP_BIN}" -help 2>&1 | tee /tmp/texturepacker-help.txt || true
if ! grep -q "Texture Packer Version 3" /tmp/texturepacker-help.txt; then
  echo "::error::编译产物不是 Kodi 22 的 TexturePacker V3" >&2
  exit 1
fi

echo "TexturePacker V3 ready: ${TP_BIN} (Kodi ${KODI_SHA})"
