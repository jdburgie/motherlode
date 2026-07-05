# Current Project Status

**Last updated:** July 4, 2026

**Branch:** `fix/self-contained-build`

## Overall status

**BROKEN / NOT PLAYABLE**

The branch has reached a useful build milestone, but not a usable game milestone.
It can currently be compiled, converted to UF2, flashed, and booted on the
Adafruit PyGamer. The display initializes and the Motherlode title screen is
visible. The firmware is nevertheless non-playable because no user input works
on the initial screen.

## Confirmed working

- Recursive submodule checkout and dependency verification
- Windows PowerShell build script
- ARM Ada compilation with the pinned toolchain
- ELF generation
- BIN generation
- UF2 generation for SAMD51 at application address `0x4000`
- Flashing the generated UF2 to the PyGamer
- Booting the application
- Initial display and title-screen rendering

## Confirmed broken

All tested title-screen input is nonfunctional:

- A button
- B button
- Start button
- Select button
- Joystick/HAT up
- Joystick/HAT down
- Joystick/HAT left
- Joystick/HAT right

Because the title screen cannot be controlled, gameplay, cargo-menu controls,
and equipment-menu controls cannot be validated on hardware.

## Input repair attempt

The pinned BSP input code was suspected of clocking the external button shift
register too quickly. A repository-local `Controls` package was added with
settling delays and explicit ADC setup for the analog joystick. The game was
rewired to use that package in:

- `src/title_screen.adb`
- `src/motherload.adb`
- `src/cargo_menu.adb`
- `src/equipment_menu.adb`

The new driver initially exposed an Ada visibility problem for `Clk_48Mhz`,
which was corrected by using the public
`SAM.Clock_Setup_120Mhz.Clk_48Mhz` declaration.

After rebuilding and flashing, the hardware result did not improve. No buttons
or joystick/HAT directions respond. Therefore the timing hypothesis remains
unproven and the replacement driver must be considered unsuccessful.

## SD-card status

**Not implemented.**

The PyGamer has an SD-card slot and the relevant SPI pins exist in the hardware,
but this branch currently contains no complete SD-card feature. It has no:

- SD block-device initialization
- SD-card SPI driver integrated into the game
- FAT filesystem
- File browser or file loading
- External asset loading
- Save-game or load-game support

Inserting an SD card currently has no effect on Motherlode.

## Build status versus product status

A successful build means only that the source compiles and the image is
created. It does **not** mean the branch is playable or hardware-complete.

Current summary:

| Area | Status |
|---|---|
| Dependency checkout | Working |
| Windows build | Working |
| UF2 generation | Working |
| Firmware boot | Working |
| Display/title screen | Working |
| Buttons | Broken |
| Joystick/HAT | Broken |
| Gameplay validation | Blocked |
| SD-card support | Not implemented |

## Exact stopping point

Work stopped for the night after the latest locally built and flashed firmware
still showed a completely unresponsive initial menu. No further fix should be
claimed until it has been compiled, flashed, and physically verified on the
PyGamer.

The next investigation should begin with a minimal hardware input diagnostic,
not another full-game guess. That diagnostic should display raw shift-register
bits and raw ADC values directly on screen so the electrical input path can be
verified independently from menu edge-detection logic.
