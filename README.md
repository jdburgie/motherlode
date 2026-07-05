# Motherlode
A 2D excavation game for the [Adafruit PyGamer](https://www.adafruit.com/product/4242),
inspired by the original [Motherload](http://www.xgenstudios.com/play/motherload) from XGen Studios.

This repository is a fork of the original Motherlode project by Fabien Chouteau.

## Project versions

- **Original upstream project:** [Fabien-Chouteau/motherlode](https://github.com/Fabien-Chouteau/motherlode)
- **Original upstream prebuilt UF2:** [motherlode 0.1.0](https://github.com/Fabien-Chouteau/motherlode/releases/download/0.1.0/motherlode.uf2)
- **Current branch build source:** [fix/world-generation-readme](https://github.com/jdburgie/motherlode/tree/fix/world-generation-readme)

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

## Current branch

The fixes under development are available from the
[current branch build source](https://github.com/jdburgie/motherlode/tree/fix/world-generation-readme).
A branch-specific UF2 release will be linked here when one is published.

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
