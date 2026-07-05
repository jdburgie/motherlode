# Motherlode
A 2D excavation game for the [Adafruit PyGamer](https://www.adafruit.com/product/4242),
inspired by the original [Motherload](http://www.xgenstudios.com/play/motherload) from XGen Studios.

This repository is a fork of the original Motherlode project by Fabien Chouteau.

## Project versions

- **Original upstream project:** [Fabien-Chouteau/motherlode](https://github.com/Fabien-Chouteau/motherlode)
- **Original upstream prebuilt UF2:** [motherlode 0.1.0](https://github.com/Fabien-Chouteau/motherlode/releases/download/0.1.0/motherlode.uf2)
- **Current self-contained source branch:** [fix/self-contained-build](https://github.com/jdburgie/motherlode/tree/fix/self-contained-build)

> The downloadable UF2 above is the **original upstream build**. A separate prebuilt UF2 for this branch has not yet been published.

Art from [kenney.nl](https://kenney.nl), font from [nfggames fontmaker](https://nfggames.com/games/fontmaker/).

# Installation

## Install the original upstream build

If you have a PyGamer:
 - Connect the PyGamer to your computer with a good USB cable
 - Turn on the PyGamer
 - Double-click the reset button to enable the UF2 bootloader
 - A `PYGAMERBOOT` disk drive should appear on your computer
 - Download the clearly labeled [original upstream motherlode.uf2](https://github.com/Fabien-Chouteau/motherlode/releases/download/0.1.0/motherlode.uf2)
 - Drag and drop `motherlode.uf2` onto the `PYGAMERBOOT` disk drive
 - After a short amount of time, the PyGamer will reboot and the game will start

# Source checkout and pinned libraries

All required source libraries and the UF2 conversion utility are included as
pinned Git submodules under `vendor/`. Clone the self-contained source branch
with:

```sh
git clone --branch fix/self-contained-build --recurse-submodules \
  https://github.com/jdburgie/motherlode.git
cd motherlode
```

For an existing checkout:

```sh
git checkout fix/self-contained-build
git submodule sync --recursive
git submodule update --init --recursive
```

The exact versions, source repositories, licenses, and commit IDs are recorded
in `DEPENDENCIES.lock`. The build scripts verify every checked-out dependency
before compiling, so a wandering submodule cannot quietly change the result.

## External toolchain

The source tree is pinned, but platform-specific compiler executables are not
stored in Git. Install these tools and place them on `PATH`:

- GNAT ARM Embedded using the `arm-eabi` target
- the `zfp-cortex-m4f` Ada runtime
- GPRbuild compatible with that GNAT installation
- Python 3
- Git

## Build on Windows PowerShell

```powershell
.\scripts\build.ps1
```

For a production build:

```powershell
.\scripts\build.ps1 -Configuration Production -Checks Enabled
```

## Build on Linux or macOS

```sh
chmod +x scripts/build.sh
./scripts/build.sh Debug Enabled
```

The scripts create:

- `obj_target/motherlode.elf`
- `build/motherlode.bin`
- `build/motherlode.uf2`

The UF2 image is generated for the SAMD51 family at application base address
`0x4000`, matching the PyGamer bootloader memory layout in the pinned BSP.

# Controls
 - `joystick up/left/right`: Fly the pod
 - `A + joystick down/left/right`: Use the drill
 - `select`: Enter and exit cargo menu

Use the drill to gather ores:

![](screenshots/screenshot4.png)

Sell it at the store:

![](screenshots/screenshot9.png)

You can then buy fuel:

![](screenshots/screenshot11.png)

And upgrades for your pod:

![](screenshots/screenshot10.png)
![](screenshots/screenshot3.png)

You will need a level 2 drill for gold and level 3 for diamonds:

![](screenshots/screenshot6.png)
![](screenshots/screenshot7.png)

If your pod is too heavy, press `select` to open the cargo menu and drop ores:

![](screenshots/screenshot8.png)
