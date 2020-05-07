#!/usr/bin/env bash

# Installs chosen Aseprite version to /Applications/Aseprite.app
# @see https://www.aseprite.org/trial/
# @see https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c

ASEPRITE_VERSION=$(
  curl --silent "https://api.github.com/repos/aseprite/aseprite/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
)

# Update SKIA_BRANCH to current required version
# @see https://github.com/aseprite/aseprite/blob/master/INSTALL.md

SKIA_BRANCH="aseprite-m81"

# Configure build directories

ROOT_DIR="$(pwd)"
DEPS_DIR="$ROOT_DIR/deps"

# Install build tools and clone Aseprite
# @see https://github.com/aseprite/aseprite/blob/master/INSTALL.md

brew install cmake ninja

if [[ -d "$ROOT_DIR/aseprite" ]]; then
  cd "$ROOT_DIR/aseprite" || exit 1
  git pull
  git submodule update --init --recursive
else
  mkdir -p "$ROOT_DIR"
  cd "$ROOT_DIR" || exit 1
  git clone --recursive https://github.com/aseprite/aseprite.git
fi

# Build dependencies
# @see https://github.com/aseprite/skia#skia-on-macos

mkdir -p "$DEPS_DIR"

if [[ -d "$DEPS_DIR/skia" ]]; then
  cd "$DEPS_DIR/skia" || exit 1
  git checkout "$SKIA_BRANCH"
  git pull
else
  cd "$DEPS_DIR" || exit 1
  git clone -b "$SKIA_BRANCH" https://github.com/aseprite/skia.git
fi

if [[ -d "$DEPS_DIR/depot_tools" ]]; then
  cd "$DEPS_DIR/depot_tools" || exit 1
  git pull
else
  cd "$DEPS_DIR" || exit 1
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

export PATH="$PWD/depot_tools:$PATH"

# Build Skia
# @see https://github.com/aseprite/skia#skia-on-macos

cd "$DEPS_DIR/skia" || exit 1
python tools/git-sync-deps
gn gen out/Release-x64 --args="is_debug=false is_official_build=true skia_use_system_expat=false skia_use_system_icu=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_sfntly=false skia_use_freetype=true skia_use_harfbuzz=true skia_pdf_subset_harfbuzz=true skia_use_system_freetype2=false skia_use_system_harfbuzz=false target_cpu=\"x64\" extra_cflags=[\"-stdlib=libc++\", \"-mmacosx-version-min=10.9\"] extra_cflags_cc=[\"-frtti\"]"
ninja -C out/Release-x64 skia modules

# Build Aseprite
# @see https://github.com/aseprite/aseprite/blob/master/INSTALL.md

mkdir -p "$ROOT_DIR/aseprite/build"
cd "$ROOT_DIR/aseprite/build" || exit 1

cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
  -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR="$DEPS_DIR/skia" \
  -DSKIA_LIBRARY_DIR="$DEPS_DIR/skia/out/Release-x64" \
  -G Ninja \
  ..

ninja aseprite

# Copy data and binary into trial version of Aseprite.app
# @see https://github.com/aseprite/aseprite/issues/589#issuecomment-73265505

DMG_NAME="Aseprite-${ASEPRITE_VERSION}-trial-macOS.dmg"

cd "$ROOT_DIR" || exit 1
curl -O "https://www.aseprite.org/downloads/trial/${DMG_NAME}"

hdiutil convert -quiet "$DMG_NAME" -format UDTO -o "$DMG_NAME"
hdiutil attach -quiet -nobrowse -noverify -noautoopen -mountpoint trial "${DMG_NAME}.cdr"
cp -R trial/Aseprite.app .
hdiutil detach trial

rm -f Aseprite.app/Contents/MacOS/aseprite
cp aseprite/build/bin/aseprite Aseprite.app/Contents/MacOS/aseprite

rm -rf Aseprite.app/Contents/Resources/data
cp -R aseprite/build/bin/data Aseprite.app/Contents/Resources/data

echo "--------------------------------------"
echo " If you see no errors above, success! "
echo "--------------------------------------"
