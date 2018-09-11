TerrainLOS is not compatible with the newest version of Contiki.
Release version 2.7 is the highest compatible version of Contiki.

arch linux packages that contiki depends on:
libmpc zlib apache-ant jdk8-openjdk arm-none-eabi-gcc arm-none-eabi-gdb lib32-gcc-libs lib32-glibc lib32-libstdc++5 lib32-zlib lib32-fakeroot

ubuntu packages that contiki depends on:
build-essential binutils-msp430 gcc-msp430 msp430-libc binutils-avr gcc-avr gdb-avr avr-libc avrdude binutils-arm-none-eabi gcc-arm-none-eabi gdb-arm-none-eabi openjdk-7-jdk openjdk-7-jre ant libncurses5-dev doxygen srecord git

The current install.sh script assumes:
* contiki's dependencies are met.
* the contiki repo doesn't exist
* the TerrainLOS doesn't exist

The current install.sh script clones contiki and TerrainLOS.
Then it sets up cooja to recognize TerrainLOS.

Who is this script meant for?
Ideally we could install the dependencies for the user.
But dependencies are tricky.
We could assume the user is using Instant Contiki.
Then we don't have to worry about dependencies.
But then the contiki repo already exists, and is possibly out of date.
