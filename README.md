## Usage

First, download the installer:
```
$ git clone https://github.com/TerrainLOS/InstallTerrainLOS
```

Next, run the installer:
```
$ bash InstallTerrainLOS/install.sh
```

## Customization

The installer will ask you questions, giving you options for
customizing the installation. You can decide if you want to:
* Install Contiki to a custom location, or use the default: `~/contiki`
* Install TerrainLOS to a custom location, or use the default: `~/TerrainLOS`
* Use a different version of Contiki and TerrainLOS

## Dependencies

The script does not handle installation of Contiki's dependencies.
If you are using Instant Contiki, the machine image already has all of these
dependencies. Otherwise, you will have to install them yourself.

To install the dependencies for Arch Linux, run:
```
sudo pacman -S libmpc zlib apache-ant jdk8-openjdk arm-none-eabi-gcc arm-none-eabi-gdb lib32-gcc-libs lib32-glibc lib32-libstdc++5 lib32-zlib lib32-fakeroot
```

To install the dependencies for Ubuntu, run:
```
sudo apt-get update
sudo apt-get install build-essential binutils-msp430 gcc-msp430 msp430-libc binutils-avr gcc-avr gdb-avr avr-libc avrdude binutils-arm-none-eabi gcc-arm-none-eabi gdb-arm-none-eabi openjdk-7-jdk openjdk-7-jre ant libncurses5-dev doxygen srecord git
```

## Compatibility

Currently, TerrainLOS supports Contiki 2.7. Support for 3.0 and 3.1 will be added soon.
