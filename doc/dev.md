# Development guide

## Getting the source code

First check out the source code.
The following commands will fetch the latest code.

```sh
# For this document we will assume you are inside a folder for development.
# We will refer to that as `dev`.
#
# I usually have a folder called `dev` in my user folder and inside a subfolder
# for each software project, here that would be `/home/user/dev/smartfield`.
# You are free to choose yours.

git clone git@github.com:opengisch/SmartField.git
# Alternatively you can use the following URL in case you have not set up SSH keys for github
#   https://github.com/opengisch/SmartField.git
```

## Linux

You need to have cmake installed.

You have two options to build SmartField. Using system packages which will
reuse packages installed from your package manager. Or using vcpkg which
will build all the packages from source.

### Using system packages

This will use your system packages.
Make sure you have installed the appropriate `-dev` or `-devel` packages
using your system package manager.
This is much faster to build than the using vcpkg and often the preferred
development method.

Installing all [QGIS development packages](https://github.com/qgis/QGIS/blob/master/INSTALL.md#33-install-build-dependencies)
is a good start. The next step is to install SmartField specific dependencies,
here is a non-exhaustive list of them on Ubuntu.

```
# TODO: update to qt6 as soon as distros start to ship qt6.5
sudo apt install libqt5sensors5-dev libqt5webview5-dev libqt5multimedia5-plugins libqt5multimedia5 qtmultimedia5-dev libzxingcore-dev libqt5bluetooth5 libqt5charts5 qml-module-qtcharts qtconnectivity5-dev qml-module-qtbluetooth qml-module-qtlocation qml-module-qtwebengine qml-module-qtgraphicaleffects qml-module-qt-labs-settings qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qtwebview qml-module-qtmultimedia qml-module-qtquick-shapes qml-module-qtsensors qml-module-qt-labs-calendar qml-module-qtquick-particles2 zipcmp zipmerge ziptool
```

### Configure
```sh
cmake -S SmartField -B build
```

If you use a locally built QGIS installed to a different
location, use `-DQGIS_ROOT=` to specify this path.

### Using vcpkg

This will build the complete dependency chain from scratch.

```sh
cmake -S SmartField -B build -DWITH_VCPKG=ON
```

Since this is now building a lot, grab yourself a cold or hot drink
and take a good break. It could well take several hours.

### Build

Now build the application.

```sh
cmake --build build
```

### Tests

To build with tests, you can specify `-DENABLE_TESTS=ON`.
To run the tests, run `ctest` in the build folder.

The testing framework `Catch2` has minimal version 3, so you might need to install it separately and pass it with `-DCatch2_ROOT=${HOME}/vcpkg/packages/catch2_x64-linux`.

## Macos

You need to have cmake and Xcode installed.

The following line will configure the build.

```sh
# We call this from the `dev` folder again
cmake -S SmartField -B build -GXcode -Tbuildsystem=1 -DWITH_VCPKG=ON
```

Please note that this will download and build the complete dependency
chain of SmartField. If you ever wanted to read a good book, you will have
a couple of hours to get started.

```sh
cmake --build build
```

## Windows

You need to have the following tools available to build

- cmake
- Visual Studio

### Configure

SmartField on Windows is always built using vcpkg.
A couple of specific variables should be specified.
The `x-buildtrees-root` flag needs to point to a short path
in order to avoid running into [issues with long paths](https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#enable-long-paths-in-windows-10-version-1607-and-later).


```sh
cmake -S SmartField -B build \
  -D VCPKG_TARGET_TRIPLET=x64-windows-static \
  -D CMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>" \
  -D PKG_CONFIG_EXECUTABLE=build/vcpkg_installed/x64-windows-static/tools/pkgconf/pkgconf.exe \
  -D VCPKG_INSTALL_OPTIONS="--x-buildtrees-root=C:/build"
```

### Build

```sh
cmake --build build
```

## Android

Android runs on a number of different CPU architectures.
The most common one is `arm64`. The platform to build for is specified via triplet.

The following triplets are possible:

- `arm64-android`
- `arm-neon-android`
- `x64-android`
- `x86-android`

### Using a docker image

There is a simple script that helps building everything by using a docker image.

```sh
triplet=arm64-android ./scripts/build.sh
```

### Building locally

Make sure you have the following tools installed

- cmake
- The Android SDK including NDK

#### Configure

```sh
export ANDROID_NDK_HOME=[path to your android ndk]
cmake -S SmartField \
      -B build \
      -D VCPKG_TARGET_TRIPLET=arm64-android
```

#### Build

```sh
cmake --build build
```

## iOS Simulators for x64 processors

To compile for iOS simulator, make sure you have installed recent versions of flex and bison (e.g. via homebrew) and added to the path.
You also need the Qt sdk for ios installed.

```sh
brew install flex bison
```

```sh
export PATH="$(brew --prefix flex)/bin:$PATH"
export PATH="$(brew --prefix bison)/bin:$PATH"
```

### Configure

```sh
cmake -S . -B build-x64-ios \
  -DVCPKG_TARGET_TRIPLET=x64-ios \
  -GXcode \
  -DWITH_VCPKG=ON \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
  -DWITH_SERIALPORT=OFF

# Build
cmake --build build-x64-ios
```

## iOS application (ARM-64 processors architecture)

```sh
# Firstly, some compilation dependencies need to be installed
# Homebrew can be used for this : https://docs.brew.sh/Installation
brew install cmake flex bison python pkg-config autoconf automake libtool autoconf-archive nasm

# Secondly, Xcode must be installed through the AppStore, then configured
xcode-select --install
sudo xcode-select --switch /Library/Developer/CommandLineTools
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -downloadPlatform iOS

# Setup the environment for the build tools
export PATH="$(brew --prefix flex)/bin:$(brew --prefix bison)/bin:$PATH"

# Configure using CMake

cmake -S . -B build-arm64-ios \
	-DVCPKG_TARGET_TRIPLET=arm64-ios \
	-DWITH_VCPKG=ON \
	-DVCPKG_BUILD_TYPE=release \
	-DCMAKE_SYSTEM_NAME=iOS \
	-DCMAKE_OSX_SYSROOT=iphoneos \
	-DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
	-GXcode

# Then, compile. To install an app on iOS, it must be signed using Xcode tools.
cmake --build build-arm64-ios
```

## Contribute

Before commiting, install pre-commit to auto-format your code.

```
pip install pre-commit
pre-commit install
```
