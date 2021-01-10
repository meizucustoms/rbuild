# RBuild
Smart, powerful and easy Android 5 - 11 build script

## Usage #1
```
$ rbuild --help
-------------------------------------------
rbuild: easy and powerful ROM build script.
Developer: @tdrkDev (Telegram, GitHub)
-------------------------------------------

Available arguments:

  --help: show this text
  --lunch: stop build after lunch command
  --installclean: run make installclean before building
  --clean: run make clean before building
  --flash: flash boot.img/ROM after successful build
  --boot: build boot.img

-------------------------------------------
```

## Usage #2
```
$ rbuild
Note: Execute rbuild --help to get available arguments. (we have built-in flasher ._.)
Welcome! Choose your lunch item, please:
Last item: aosp_m1721-eng. Will we use it? (Y/n)
@bin/rbuild> y
Item aosp_m1721-eng was chosen.
[@bin/rbuild::config] Detected 7937MB of RAM, heap decreasing will be enabled, because of <8GB of RAM.
[@bin/rbuild::config] Starting envsetup...
[@bin/rbuild::config] Eat a lunch...
Trying dependencies-only mode on a non-existing device tree?

============================================
PLATFORM_VERSION_CODENAME=REL
PLATFORM_VERSION=10
CUSTOM_VERSION=PixelExperience_m1721-10.0-20210110-0821-UNOFFICIAL
TARGET_PRODUCT=aosp_m1721
TARGET_BUILD_VARIANT=eng
TARGET_BUILD_TYPE=release
TARGET_ARCH=arm64
TARGET_ARCH_VARIANT=armv8-a
TARGET_CPU_VARIANT=generic
TARGET_2ND_ARCH=arm
TARGET_2ND_ARCH_VARIANT=armv8-a
TARGET_2ND_CPU_VARIANT=generic
HOST_ARCH=x86_64
HOST_2ND_ARCH=x86
HOST_OS=linux
HOST_OS_EXTRA=Linux-5.10.5-arch1-1-x86_64-Arch-Linux
HOST_CROSS_OS=windows
HOST_CROSS_ARCH=x86
HOST_CROSS_2ND_ARCH=x86_64
HOST_BUILD_TYPE=release
BUILD_ID=QQ3A.200805.001
OUT_DIR=/home/tdrk/ameizu/out
PRODUCT_SOONG_NAMESPACES=vendor/meizu/m1721 device/meizu/m1721 hardware/qcom-caf/msm8996 hardware/qcom-caf/common/fwk-detect
============================================
[@bin/rbuild::config] Detecting your Android version...
[@bin/rbuild::config] We will build Android 10...
[@bin/rbuild::ccache] Starting...
[@bin/rbuild::config] Overwriting necessary build variables...
============================================
PLATFORM_VERSION_CODENAME=REL
PLATFORM_VERSION=10
CUSTOM_VERSION=PixelExperience_m1721-10.0-20210110-0821-UNOFFICIAL
TARGET_PRODUCT=aosp_m1721
TARGET_BUILD_VARIANT=eng
TARGET_BUILD_TYPE=release
TARGET_ARCH=arm64
TARGET_ARCH_VARIANT=armv8-a
TARGET_CPU_VARIANT=generic
TARGET_2ND_ARCH=arm
TARGET_2ND_ARCH_VARIANT=armv8-a
TARGET_2ND_CPU_VARIANT=generic
HOST_ARCH=x86_64
HOST_2ND_ARCH=x86
HOST_OS=linux
HOST_OS_EXTRA=Linux-5.10.5-arch1-1-x86_64-Arch-Linux
HOST_CROSS_OS=windows
HOST_CROSS_ARCH=x86
HOST_CROSS_2ND_ARCH=x86_64
HOST_BUILD_TYPE=release
BUILD_ID=QQ3A.200805.001
OUT_DIR=/home/tdrk/ameizu/out
PRODUCT_SOONG_NAMESPACES=vendor/meizu/m1721 device/meizu/m1721 hardware/qcom-caf/msm8996 hardware/qcom-caf/common/fwk-detect
============================================

... now build is going
```
