#!/bin/bash
#
# Copyright (C) Roman Rihter 2020 - 2021
#
# -------------
# RBuild script
# -------------

#
# Device settings
#
BUILD_PATHS=("$HOME/xiaomeme")            # Paths to Android sources
DEVICE_TABLE=("i_wanna_sell_mixer")       # Device codenames
# Example:
# BUILD_PATHS=("device #1 path" "device #2 path")
# DEVICE_TABLE=("device #1" "device #2")

#
# Lunch settings
#
ROM_LUNCH_PREFIXES=("aosp_")                # All ROMs lunch prefixes, e.g. aosp_, pixel_, lineage_, rr_, mokee_, ...
AVAILABLE_BUILD_VARIANTS=("eng" "userdebug") # All device build variants (eng, userdebug, user are available for LOS and AOSP.)

#
# Old Android building settings (older than 9)
#
TJAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64-old" # Old Google's prebuilt Java directory
PYTHON_VENV_DIR="$HOME/venv"                       # Python 2.7 virtual enviroment directory

######################################

# Tput
tput_beep="$(tput bel)"

# Text operations; not colouring
text_reset='\e[0m'
text_bold='\e[1m'
text_dim='\e[2m'        # Half-brigtness
text_underline='\e[4m'
text_blink='\e[5m'
text_invert='\e[7m'     # Invert colors
text_hide="\e[8m"

# Colors
color_default='\e[39m'
color_black='\e[30m'
color_red='\e[31m'
color_green='\e[32m'
color_yellow='\e[33m'
color_blue='\e[34m'
color_magenta='\e[35m'
color_cyan='\e[36m'
color_lightGray='\e[37m'
color_darkGray='\e[90m'
color_lightRed='\e[91m'
color_lightGreen='\e[92m'
color_lightYellow='\e[93m'
color_lightBlue='\e[94m'
color_lightMagenta='\e[95m'
color_lightCyan='\e[96m'
color_white='\e[97m'

function log() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "[log] Not enough arguments."
  fi

  if [ "$1" = "tag" ]; then
    LOG_TAG="$2"
    return 0
  fi

  echo -e ${text_bold}"[$LOG_TAG::$1]${text_reset} $2"${text_reset}

  return 0
}

function logError() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "[logError] Not enough arguments."
  fi

  echo -e "${text_bold}[$LOG_TAG::$1] ${text_reset}${color_lightRed}ERROR: ${text_reset}${text_bold}${2}"${text_reset}

  return 1
}

function logFatal() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "[logFatal] Not enough arguments."
  fi

  echo -e "${text_bold}${color_red}[$LOG_TAG::$1] FATAL: $2"${text_reset}

  exit 1
}

function configurator() {
  for ((a=0;$a<${#DEVICE_TABLE[@]};a++)); do
    for ((b=0;$b<${#ROM_LUNCH_PREFIXES[@]};b++)); do
      for ((c=0;$c<${#AVAILABLE_BUILD_VARIANTS[@]};c++)); do
        ALLBUILDVARIANTS+=("${ROM_LUNCH_PREFIXES[$b]}${DEVICE_TABLE[$a]}-${AVAILABLE_BUILD_VARIANTS[$c]}")
      done
    done
  done

  for ((d=0;$d<${#ALLBUILDVARIANTS[@]};d++)); do
    echo -e ${text_bold}${color_yellow}"#$(expr $d + 1):${text_reset} ${ALLBUILDVARIANTS[$d]}"${text_reset}
  done
  echo
  echo -e ${text_bold}"Please, choose one:"${text_reset}
  echo -ne ${text_bold}${color_yellow}"@bin/rbuild> "${text_reset}
  read choice
  [ -z "$choice"ccacheStart

  if [ -z $CHOSENDEVICE ]; then
    logFatal config "Lunch item $choice not found."
  fi
}

function configure() {
  echo -e ${text_bold}${color_yellow}"Welcome!${text_reset} Choose your lunch item, please:"${text_reset}
  if [ -f $HOME/.build_device.last ]; then
    LASTDEVICE="$(cat $HOME/.build_device.last)"
    echo -e ${text_bold}${color_yellow}"Last item:"${text_reset}" $LASTDEVICE. Will we use it? (Y/n)"${text_reset}
    echo -ne ${text_bold}${color_yellow}"@bin/rbuild> "${text_reset}
    read choice
    case "$choice" in
    n|N) echo -e ${text_reset}"Ok, let's${color_yellow}${text_bold} choose other item..."${text_reset}
    configurator
    ;;
    *) CHOSENDEVICE="$LASTDEVICE"
    ;;
    esac
  else
    configurator
  fi

  echo "$CHOSENDEVICE" > $HOME/.build_device.last
  echo -e ${text_reset}"Item "${text_bold}${color_yellow}$CHOSENDEVICE${text_reset}" was chosen."

  return 0
}

function setsrccfg() {
  for ((i=0;$i<${#DEVICE_TABLE[@]};i++)); do
    if [ "$(echo $CHOSENDEVICE | grep "${DEVICE_TABLE[$i]}" 2>/dev/null >/dev/null && echo $?)" = "0" ]; then
      DEVICEDIR="${BUILD_PATHS[$i]}"
      DEVICENAME="${DEVICE_TABLE[$i]}"
      break
    fi
  done

  for ((i=0;$i<${#ROM_LUNCH_PREFIXES[@]};i++)); do
    if [ "$(echo $CHOSENDEVICE | grep "${ROM_LUNCH_PREFIXES[$i]}" 2>/dev/null >/dev/null && echo $?)" = "0" ]; then
      DEVICEPREFIX="${ROM_LUNCH_PREFIXES[$i]}"
      break
    fi
  done
}

function ccacheStart() {
  log ccache "Starting..."
  ccache -M 50G >/dev/null || logError ccache "Failed! (non-fatal)" || return 1
  export USE_CCACHE=true
  export CCACHE_SIZE=50G
  [ ! -d $HOME/.cachebuild ] && mkdir $HOME/.cachebuild
  export CCACHE_DIR="$HOME/.cachebuild"
}

function buildconfig() {
  [ ! -f $DEVICEDIR/build/envsetup.sh ] && logFatal config "envsetup.sh not found!"

  RAMTOTAL="$(expr $(cat /proc/meminfo | grep MemTotal | sed 's/MemTotal:...*  //g' | sed 's/ kB//g') / 1024)"

  if (($RAMTOTAL>8192)); then
    MINIRAM=false
    OUTMSGTEMP="disabled"
  else
    MINIRAM=true
    OUTMSGTEMP="enabled, because of <8GB of RAM"
  fi

  log config "Detected ${RAMTOTAL}MB of RAM, heap decreasing will be $OUTMSGTEMP."

  log config "Starting envsetup..."
  cd $DEVICEDIR && source build/envsetup.sh >/dev/null

  log config "Eat a lunch..."
  cd $DEVICEDIR && lunch $CHOSENDEVICE || logFatal config "Failed eating lunch!"

  log config "Detecting your Android version..."

  # Use built-in get_build_var function to get Ninja's build variable
  DEVICEANDROID="$(get_build_var PLATFORM_VERSION)"

  if [ -z "$DEVICEANDROID" ]; then
    logFatal config "Failed to detect Android version, check your sources for function get_build_var."
  fi

  log config "We will build Android $DEVICEANDROID..."

  ccacheStart

  log config "Overwriting necessary build variables..."

  if [ $MINIRAM = true ] && [ "$(getArg --boot)" = "false" ]; then
    export _JAVA_OPTIONS="-Xmx4G"
  fi

  if [ $DEVICEANDROID -lt 9 ]; then
    log config "Fixing build for Android older than 9..."
    export LC_ALL=C
    [ ! -d $PYTHON_VENV_DIR ] && logFatal build "Please create Python 2.7 virtualenv in $PYTHON_VENV_DIR."
    [ ! -d $TJAVA_HOME ] && logFatal build "Please install Google's Java into $TJAVA_HOME."
    source $PYTHON_VENV_DIR/bin/activate
    export ANDROID_JAVA_HOME=$TJAVA_HOME
    export JAVA_HOME=$ANDROID_JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
    if [ "$(getArg --boot)" = "false" ]; then
        if [ $MINIRAM = true ]; then
            log config "Target: ROM, fixing JACK..."
            $DEVICEDIR/prebuilts/sdk/tools/jack-admin kill-server >/dev/null 2>/dev/null
            export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
            export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
            $DEVICEDIR/prebuilts/sdk/tools/jack-admin start-server >/dev/null 2>/dev/null
        fi
    else
        if [ $MINIRAM = true ]; then
            log config "Target: Boot Image, skipped JACK server restart..."
            # to skip ninja regeneration
            export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
            export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
        fi
    fi
  fi
}

function build() {
  if [ "$(getArg --clean)" = "true" ] && [ $DEVICEANDROID -gt 10 ]; then
    cd $DEVICEDIR && rm -rf out
    log build "Cleaning..."
  elif [ "$(getArg --clean)" = "true" ]; then
    cd $DEVICEDIR && make clean
    log build "Cleaning..."
  fi

  if [ "$(getArg --installclean)" = "true" ]; then
    log build "Cleaning... (installclean)"
    cd $DEVICEDIR && make installclean
  fi

  if [ "$(getArg --lunch)" = "false" ]; then
    if [ "$(getArg --boot)" = "true" ]; then
      cd $DEVICEDIR && make bootimage -j$(expr $(nproc --all) \* 6) || BUILDFAILED=1
    else
      cd $DEVICEDIR && make bacon -j$(expr $(nproc --all) + 1) || BUILDFAILED=1
    fi
  fi
}

function flash() {
      if [ "$(getArg --flash)" = "false" ]; then
          return 0
      fi

      if [ ! -z $BUILDFAILED ]; then
          logFatal flash "Stop flash because of build error..."
      fi

      log flash "Start flash..."

      if [ "$(getArg --boot)" = "true" ]; then
          DEVNOTFOUND=0
          DEVICEMODE="android"
          if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
              if [ -z "$(fastboot devices 2>/dev/null)" ]; then
                  logError flash "Device not found. ${text_bold}(Fastboot)${text_reset}"
                  log flash "Please connect device with ${text_bold}booted Android/fastboot${text_reset} and press ENTER."
                  read abc
                  if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
                      logError flash "Device not found. ${text_bold}(Android)${text_reset}"
                      DEVNOTFOUND=1
                  fi
                  if [ -z "$(fastboot devices 2>/dev/null)" ]; then
                      if [ $DEVNOTFOUND = 1 ]; then
                          logFatal flash "Device not found. ${text_bold}(Fastboot)${text_reset}"
                      fi
                  fi
              else
                  DEVICEMODE="fastboot"
              fi
          fi

          if [ $DEVICEMODE = android ]; then
              log flash "Rebooting to ${text_bold}bootloader${text_reset}..."
              adb reboot bootloader >/dev/null 2>/dev/null
          fi

          for ((total=0;$total<20;total++)); do
              if [ ! -z "$(fastboot devices)" ]; then
                  log flash "Reached target ${text_bold}'bootloader'${text_reset} in ${text_bold}${color_yellow}${total}${text_reset} seconds."
                  fastboot flash boot $DEVICEDIR/out/target/product/$DEVICENAME/boot.img >/dev/null 2>/dev/null || logFatal flash "Error on flashing."
                  fastboot reboot >/dev/null 2>/dev/null || logFatal flash "Error on ${text_bold}reboot.${text_reset}"
                  log flash "Reached target ${text_bold}'flash_success'${text_reset}."
                  break
              fi

              if [ $total = 19 ]; then
                  logFatal flash "Failed to enter fastboot in ${text_bold}20s.${text_reset}"
              fi

              sleep 1
          done
      elif [ "$(getArg --boot)" = "false" ]; then
          DEVNOTFOUND=0
          DEVICEMODE="android"
          if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
              if [ "$(adb get-state 2>/dev/null)" != "recovery" ]; then
                  logError flash "Device not found. ${text_bold}(Recovery, Android)${text_reset}"
                  log flash "Please connect device with ${text_bold}booted Android/recovery${text_reset} and press ${text_bold}ENTER.${text_reset}"
                  read abc
                  if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
                      logError flash "Device not found. ${text_bold}(Android)${text_reset}"
                      DEVNOTFOUND=1
                  fi
                  if [ "$(adb get-state 2>/dev/null)" != "recovery" ]; then
                      if [ $DEVNOTFOUND = 1 ]; then
                          logFatal flash "Device not found. ${text_bold}(Recovery)${text_reset}"
                      fi
                  fi
              else
                  DEVICEMODE="recovery"
              fi
          fi

          if [ $DEVICEMODE = android ]; then
              log flash "Rebooting to ${text_bold}recovery...${text_reset}"
              adb reboot recovery >/dev/null 2>/dev/null
          fi

          for ((total=0;$total<20;total++)); do
              if [ "$(adb get-state 2>/dev/null)" = "recovery" ]; then
                  log flash "Reached target ${text_bold}'recovery::uploadROM'${text_reset} in ~${text_bold}${color_yellow}${total}${text_reset}s."
                  adb push $(ls $DEVICEDIR/out/target/product/$DEVICENAME/$DEVICEPREFIX$DEVICENAME-ota*) /sdcard/flash.zip >/dev/null 2>/dev/null
                  log flash "Reached target ${text_bold}'recovery::createORS'${text_reset}."
                  adb shell "echo 'install /sdcard/flash.zip' > /cache/recovery/openrecoveryscript && echo 'reboot' >> /cache/recovery/openrecoveryscript" >/dev/null 2>/dev/null
                  log flash "Reached target ${text_bold}'recovery::flashByOTA'${text_reset}."
                  adb reboot recovery >/dev/null 2>/dev/null
                  log flash "Reached target ${text_bold}'flash'${text_reset}."
                  break
              fi

              if [ $total = 59 ]; then
                  logFatal flash "Failed to enter ${text_bold}recovery${text_reset} in ${text_bold}60s."
              fi

              sleep 1
          done

          adb get-state 2>/dev/null
      fi

      for ((i=0;$i<300;i++)); do
          if [ "$(adb get-state 2>/dev/null)" = "device" ]; then
              [ -z $BOOTREACHED ] && log flash "Reached target ${text_bold}'boot'${text_reset} in ${text_bold}${color_yellow}${i}${text_reset}s. (Flash time: ~${text_bold}${color_yellow}${total}${text_reset}s)" && BOOTREACHED=1
              if [ "$(adb shell getprop sys.boot_completed)" = "1" ]; then
                  log flash "Reached target ${text_bold}'boot_completed'${text_reset} in ${text_bold}${color_yellow}${i}${text_reset}s, take log... (Flash time: ~${text_bold}${color_yellow}${total}${text_reset}s)"
                  adb logcat -b all -d > $DEVICEDIR/logcat.txt || logFatal flash "Error on ${text_bold}taking logcat${text_reset}."
                  atom $DEVICEDIR/logcat.txt
                  exit 0
              fi
          fi

          sleep 1
          ((total++))
      done
}

if [ ! -z "$1" ]; then
  for i in $@; do
    args+=("$i")
  done
  ARGSEXIST=true
else
  ARGSEXIST=false
  echo -e ${color_lightBlue}"Note:${color_default} Execute${text_bold}${color_lightYellow} $0 --help${text_reset} to get available arguments. (we have built-in flasher ._.)"
fi

function getArg() {
  if [ -z "$1" ]; then
    echo error
    return 1
  fi

  if [ "$ARGSEXIST" = "true" ]; then

  for ((i=0;$i<${#args[@]};i++)); do
    if [ "${args[$i]}" = "$1" ]; then
      echo true
      return 0
    fi
  done

  fi

  echo false
  return 0
}

function checkDefault() {
  if [ ${#BUILD_PATHS[@]} = 1 ] && [ ${BUILD_PATHS[0]} = "$HOME/xiaomeme" ]; then
    if [ ${#DEVICE_TABLE[@]} = 1 ] && [ ${DEVICE_TABLE[0]} = "i_wanna_sell_mixer" ]; then
      echo true
      return 0
    fi
  fi

  echo false
  return 0
}

function printHelp() {
  echo -e "${color_lightYellow}${text_bold}-------------------------------------------${text_reset}"
  echo -e "${color_lightYellow}${text_bold}rbuild${text_reset}: easy and powerful ROM build script."
  echo -e "Developer:${color_lightYellow}${text_bold} @tdrkDev (Telegram, GitHub)${text_reset}"
  echo -e "${color_lightYellow}${text_bold}-------------------------------------------${text_reset}"
  echo
  echo -e "${color_lightYellow}${text_bold}Available arguments:${text_reset}"
  echo
  echo -e "  ${color_lightYellow}${text_bold}--help${text_reset}: show this text"
  echo -e "  ${color_lightYellow}${text_bold}--lunch${text_reset}: stop build after lunch command"
  echo -e "  ${color_lightYellow}${text_bold}--installclean${text_reset}: run make installclean before building"
  echo -e "  ${color_lightYellow}${text_bold}--clean${text_reset}: run make clean before building"
  echo -e "  ${color_lightYellow}${text_bold}--flash${text_reset}: flash boot.img/ROM after successful build"
  echo -e "  ${color_lightYellow}${text_bold}--boot${text_reset}: build boot.img"
  echo
  echo -e "${color_lightYellow}${text_bold}-------------------------------------------${text_reset}"
  if [ $(checkDefault) = true ]; then
    echo
    echo -e "${color_lightRed}${text_bold}CHANGE SETTINGS IN SCRIPT BEFORE USING IT!${text_reset}"
    echo -e "${color_lightRed}${text_bold}(they are located in top of the script)${text_reset}"
    echo
    echo -e "${color_lightYellow}${text_bold}-------------------------------------------${text_reset}"
  fi
}

function checkArguments() {
  if [ "$ARGSEXIST" = "false" ]; then
    return 0
  fi

  if ((${#args[@]}<2)); then
    return 0
  fi

  if [ "$(getArg --lunch)" = "true" ] && [ "$(getArg --installclean)" = "true" ]; then
    logFatal checks "Arguments logical error."
  fi

  if [ "$(getArg --lunch)" = "true" ] && [ "$(getArg --clean)" = "true" ]; then
    logFatal checks "Arguments logical error."
  fi

  if [ "$(getArg --lunch)" = "true" ] && [ "$(getArg --boot)" = "true" ]; then
    logFatal checks "Arguments logical error."
  fi

  if [ "$(getArg --lunch)" = "true" ] && [ "$(getArg --flash)" = "true" ]; then
    logFatal checks "Arguments logical error."
  fi

  if [ "$(getArg --clean)" = "true" ] && [ "$(getArg --installclean)" = "true" ]; then
    logFatal checks "Arguments logical error."
  fi

  return 0
}

function main() {
  if [ "$(getArg --help)" = "true" ]; then 
    printHelp
    exit 0
  fi

  log tag "@bin/rbuild"

  checkArguments

  configure
  setsrccfg
  buildconfig "$1"

  if [ $(getArg --lunch) = "false" ]; then
    build "$1"
    if [ $(getArg --flash) = "true" ]; then
     flash "$1" "$2"
    fi
  fi
}

main
