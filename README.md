Plasma Nano
## Introduction
A minimal plasma shell package intended for embedded devices

Test on a development machine

## Depends
Plasma-Nano depends the following:
- Qt5
- KF5
- ECM
- cmake


## Building and Installing

```sh
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/path/to/prefix ..
make
make install # use sudo if necessary
```

Replace `/path/to/prefix` to your installation prefix.
Default is `/usr/local`.

##Usage
plasmashell -p org.kde.plasma.nano
