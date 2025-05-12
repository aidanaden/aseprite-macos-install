#!/bin/bash
#
# Clean installation and compilation of aseprite on aarch64-macos

function cleanup() {
  rm -rf aseprite
  rm -rf mount
  rm -rf *.zip
  rm -rf *.app
  rm -rf *.dmg
}

function check_xcode() {
  printf "On macOS you will need macOS 15.4 SDK and Xcode 16.3 (older versions might work)."
  printf "\n\nYour Xcode version:\n$(xcodebuild -version | tr '\n' ' ')"
  printf "\n\nYour SDK version:\n$(xcodebuild -showsdks | grep macOS)" | tr -d '\t'
  printf "\n\n"
}

function download() {
  git clone --recursive https://github.com/aseprite/aseprite.git
  cd aseprite && git pull && git checkout v1.3.13 && git submodule update --init --recursive && cd ..
}

function install_build_deps() {
  brew install cmake ninja
}

function download_skia() {
  curl -O -L 'https://github.com/aseprite/skia/releases/download/m102-861e4743af/Skia-macOS-Release-arm64.zip'
  mkdir -p aseprite/skia-m102
  unzip Skia-macOS-Release-arm64.zip -d aseprite/skia-m102
}

function build() {
  cd aseprite && mkdir -p build && cd build
  cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DLAF_BACKEND=skia \
    -DUSE_SHARED_LIBPNG=on \
    -DSKIA_DIR=../skia-m102 \
    -DSKIA_LIBRARY_DIR=../skia-m102/out/Release-arm64 \
    -DSKIA_LIBRARY=../skia-m102/out/Release-arm64/libskia.a \
    -DPNG_ARM_NEON:STRING=on \
    -G Ninja .. && \
  ninja aseprite
  cd ..
}

function build_app() {
  curl -O -J "https://www.aseprite.org/downloads/trial/Aseprite-v1.3.9.1-trial-macOS.dmg"
  mkdir mount
  yes qy | hdiutil attach -quiet -nobrowse -noverify -noautoopen -mountpoint mount ./Aseprite-v1.3.9.1-trial-macOS.dmg
  cp -r mount/Aseprite.app .
  hdiutil detach mount

  # printf 'Copy built aseprite to app? (y/n)? '
  #   read answer
  # if [ "$answer" != "${answer#[Yy]}" ] ;then
  #   echo Yes
  # else
  #   echo No
  # fi

  rm -rf ./Aseprite.app/Contents/MacOS/aseprite
  cp -r ./build/bin/aseprite ./Aseprite.app/Contents/MacOS/aseprite
  rm -rf ./Aseprite.app/Contents/Resources/data
  cp -r ./build/bin/data Aseprite.app/Contents/Resources/data
}

function install_app() {
  sudo cp  -r ./Aseprite.app /Applications/
}

cleanup
check_xcode
download
install_build_deps
download_skia
build && build_app
install_app
