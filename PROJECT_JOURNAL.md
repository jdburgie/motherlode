# Motherlode SD Save Project Journal

This file is the canonical handoff record for the SD-card save and high-score modification. Keep it current so work can resume from any computer without relying on chat history or local notes.

## Resume in One Minute

### Fresh computer

```bash
git clone https://github.com/jdburgie/motherlode.git
cd motherlode
git fetch --all --prune
git switch feature/sd-save-highscores
```

Then read, in order:

1. `PROJECT_JOURNAL.md`
2. `docs/SD_SAVE_DESIGN.md`
3. The latest commits:

```bash
git log --oneline --decorate -10
```

### Existing clone

Before doing anything else:

```bash
cd motherlode
git status
git fetch origin --prune
git switch feature/sd-save-highscores
git pull --ff-only origin feature/sd-save-highscores
```

Do not discard or overwrite uncommitted work. If `git status` is not clean, commit it to a temporary branch or stash it with a descriptive message before pulling.

## Repository Coordinates

- Working repository: `https://github.com/jdburgie/motherlode`
- Original upstream: `https://github.com/Fabien-Chouteau/motherlode`
- Default branch: `master`
- Development branch: `feature/sd-save-highscores`
- Target hardware: Adafruit PyGamer M4
- Language: Ada
- Project file: `motherlode.gpr`

Recommended remotes for a local clone:

```bash
git remote -v
git remote add upstream https://github.com/Fabien-Chouteau/motherlode.git
```

If `upstream` already exists, do not add it again.

## Current Objective

Add persistent game-state saving and high scores using a 4 GB microSD card in the PyGamer while preserving the original game's behavior when no usable card is present.

The finished modification should support:

- Continue an existing game.
- Save player position, money, fuel, cargo, equipment, depth, and mine state.
- Persistent high scores.
- Power-loss-safe alternating save slots.
- A pause/save menu and updated title screen.
- A release UF2 that can be copied to `PYGAMERBOOT`.

## Current Status

**Last updated:** 2026-07-03 MDT

**Phase:** Design complete, implementation not yet started.

Completed:

- Fork created at `jdburgie/motherlode`.
- Development branch created: `feature/sd-save-highscores`.
- Save-system architecture documented in `docs/SD_SAVE_DESIGN.md`.
- Initial design commit: `d126e06`.
- Confirmed that player state is centralized in `src/player.ads` and `src/player.adb`.
- Confirmed that the mine is a 30 x 600 cell array in `src/world.ads`.
- Confirmed that a fresh world and player are currently created every time `Motherload.Run` starts.
- Confirmed that the title screen currently offers only New Game and Credits.

Not yet completed:

- Local build environment has not been reproduced or documented.
- No Ada source files have been changed for persistence.
- SD SPI initialization and FAT mounting have not been implemented.
- No simulator tests, hardware tests, or release UF2 exist for this branch.

## Active Task

**Next exact task:** establish a reproducible clean build of the unmodified branch and record the required Ada/Alire toolchain, dependency, build, and UF2-generation commands in this journal.

Do not begin the SD driver until the original code builds successfully from a clean checkout. This gives us a known-good runway instead of debugging the airplane and the runway at the same time.

## Important Design Decisions

### Card and filesystem

- Use a card with an MBR partition table.
- Use the first FAT32 partition.
- Store files under `/MOTHERLD/`.
- The game must still start when the card is absent or unreadable, but Continue and Save will be unavailable.

### Save files

Use alternating copies:

```text
/MOTHERLD/SAVEA.DAT
/MOTHERLD/SAVEB.DAT
/MOTHERLD/SCOREA.DAT
/MOTHERLD/SCOREB.DAT
```

Load the valid copy with the highest generation number. Never overwrite the only known-good copy.

### Save format

- Magic: `MLOD`
- Explicit version number.
- Little-endian integer encoding.
- CRC-32 over the payload.
- Do not serialize Ada physics objects or compiler-dependent record layouts directly.
- Store fuel as integer thousandths rather than as a raw floating-point value.
- Store each world cell as one explicit byte.

### Player restoration

Loading must reconstruct runtime state rather than restoring opaque memory:

- Position restored and validated.
- Speed reset to zero.
- Cargo total recalculated.
- Vehicle mass recalculated.
- Drill animation and movement flags cleared.
- Fuel, cargo, equipment, and coordinates clamped to valid ranges.

### Autosave policy

Autosave only at safe checkpoints such as:

- After cargo is sold.
- After an equipment purchase.
- After refueling.
- During Save and Quit.

Do not write continuously during the frame loop.

## Hardware Notes

The built-in microSD interface uses the normal SPI controller, separate from the display SPI controller.

```text
SD SPI controller: SERCOM1
SCK:               PA17
MOSI:              PB23
MISO:              PB22
Chip select:       PA14
Initial clock:     approximately 400 kHz
Normal clock:      approximately 3 MHz
SPI mode:          Mode 0
```

The mine contains 18,000 cells. Using one byte per persisted cell requires approximately 18 KB per world payload, trivial on a 4 GB card.

## Implementation Roadmap

### Stage 0: Reproduce the original build

- Identify and install the required Ada toolchain.
- Identify project dependencies and exact revisions.
- Build the original firmware from a clean clone.
- Generate or locate the UF2 conversion step.
- Record flash and RAM use.
- Flash and smoke-test the original build on the PyGamer.

### Stage 1: Portable in-memory state

Modify `Player` to expose a portable save-state type and:

- `Export_State`
- `Import_State`
- `Maximum_Depth`
- `Net_Worth`

Add world-cell encoding and decoding helpers without changing gameplay.

### Stage 2: Serialization core

Add:

- Explicit byte writer and reader helpers.
- Save header encoder/decoder.
- CRC-32.
- Strict validation for damaged or future-version files.
- In-memory round-trip tests using the simulator where possible.

### Stage 3: SD block driver and FAT

- Initialize SERCOM1 and PA14.
- Implement or integrate a 512-byte block driver.
- Mount the first FAT partition.
- Create `/MOTHERLD/` when absent.
- Confirm read, write, flush, close, and remount behavior.

### Stage 4: Save manager

- Implement alternating A/B save slots.
- Validate magic, version, length, and CRC.
- Choose the newest valid generation.
- Preserve the previous slot until the new save is completely flushed.
- Fail gracefully on removal or write errors.

### Stage 5: Menus and gameplay integration

Title screen:

```text
Continue
New Game
High Scores
Credits
```

Pause menu:

```text
Resume
Save Game
Save and Quit
Retire Run
```

Add checkpoint autosaves and visible success/error feedback.

### Stage 6: High scores

Persist up to ten records containing:

- Run ID
- Composite score
- Maximum depth
- Highest cash balance
- Net worth

Provisional score formula:

```text
money + purchased-upgrade value + maximum-depth-in-cells * 100
```

### Stage 7: Hardware and power-loss testing

Test:

- No card installed.
- Blank FAT32 card.
- Existing valid save.
- One corrupted slot.
- Both corrupted slots.
- Card removed during play.
- Power removed at several points during a save.
- Full or write-protected card.
- Save made by an older format version.

Then build and publish a tested UF2.

## Known Risks

- The existing PyGamer Ada BSP does not currently expose an obvious ready-made SD-card package.
- FAT support and an SD protocol layer may increase firmware size significantly.
- The PyGamer project has roughly 496 KB of application flash after the UF2 bootloader reservation, so final link size must be watched.
- The current gameplay loop does not naturally return to the title screen, so Save and Quit requires a controlled exit path.
- The original game does not define a formal game-over condition, so high-score submission needs a Retire Run action or continuous personal-best updates.
- Save compatibility must be explicit from the first release. Never assume Ada enum or record representation remains unchanged.

## Working Rules

1. Work only on `feature/sd-save-highscores` unless intentionally creating a narrower sub-branch.
2. Keep commits small enough to explain and test.
3. Do not mix broad formatting changes with functional changes.
4. Update this journal before ending every work session.
5. Record commands that actually ran, not commands that merely look plausible.
6. Record test hardware, card format, result, and any visible symptoms.
7. Push completed work before leaving a computer station.
8. Never commit private credentials, tokens, local paths containing secrets, or card images containing personal data.

## End-of-Session Checklist

Run:

```bash
git status
git diff --check
git log --oneline --decorate -5
```

Then:

- Build and run the most relevant available tests.
- Commit all intended changes with a descriptive message.
- Push the branch.
- Update Current Status, Active Task, and Session Log below.
- Include the exact next file/function to edit.

## Session Log

### 2026-07-03, repository setup and architecture

**Completed**

- Forked `Fabien-Chouteau/motherlode` to `jdburgie/motherlode`.
- Created `feature/sd-save-highscores` from `master`.
- Inspected the player, world, main loop, and title screen architecture.
- Confirmed the relevant PyGamer SD pins and separate screen/SD SPI controllers.
- Added `docs/SD_SAVE_DESIGN.md` in commit `d126e06`.
- Added this portable project journal.

**Tests**

- Repository permissions and branch creation verified through GitHub.
- No firmware build or hardware test performed yet.

**Next action**

- Clone the branch on a development workstation.
- Reproduce the original clean build.
- Append the exact installation and build commands here.

## New Session Entry Template

Copy this section to the top of the Session Log after each work session:

```markdown
### YYYY-MM-DD, short session title

**Starting point**

- Branch:
- Starting commit:
- Machine/OS:
- Hardware connected:

**Completed**

- 

**Files changed**

- `path`: reason

**Commands run**

```text
paste exact commands here
```

**Tests and results**

- 

**Commits pushed**

- `abcdef0` Description

**Problems or unresolved questions**

- 

**Next exact action**

- Open `path` and implement/check ...
```
