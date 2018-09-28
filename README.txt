## install.sh

The install script is interactive script that prompts for user input. It will:
* Install Contiki to a specified location, or use the default ~/contiki path.
* Install TerrainLOS to a specified location.
* Allow the user to checkout a different branch of Contiki and TerrainLOS
* Build and register TerrainLOS as a Cooja Extension

## dependencies

The script does not handle installation of Contiki's dependencies. If you are using Instant Contiki, the machine image already has all of these dependencies. Otherwise, you will have to install them yourself.

Here is a list of Arch Linux packages required by Contiki:
libmpc zlib apache-ant jdk8-openjdk arm-none-eabi-gcc arm-none-eabi-gdb lib32-gcc-libs lib32-glibc lib32-libstdc++5 lib32-zlib lib32-fakeroot

And the same for Ubuntu:
build-essential binutils-msp430 gcc-msp430 msp430-libc binutils-avr gcc-avr gdb-avr avr-libc avrdude binutils-arm-none-eabi gcc-arm-none-eabi gdb-arm-none-eabi openjdk-7-jdk openjdk-7-jre ant libncurses5-dev doxygen srecord git

## compatibility

Currently, TerrainLOS supports Contiki 2.7. Support for 3.0 and 3.1 will be added soon.
