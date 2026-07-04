# Motherlode SD Save Project Journal

This is the canonical handoff record for the SD-card save and high-score modification. Keep it current so work can resume from any computer without relying on chat history or local notes.

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
3. `.github/workflows/build-pygamer-uf2.yml`
4. The latest commits:

```bash
git log --oneline --decorate -15
```

### Existing clone

```bash
cd motherlode
git status
git fetch origin --prune
git switch feature/sd-save-highscores
git pull --ff-only origin feature/sd-save-highscores
```

Do not discard uncommitted work. Commit it to a temporary branch or stash it with a descriptive message before pulling.

## Repository Coordinates

- Working repository: `https://github.com/jdburgie/motherlode`
- Original upstream: `https://github.com/Fabien-Chouteau/motherlode`
- Default branch: `master`
- Development branch: `feature/sd-save-highscores`
- Draft pull request: `#1`, Build PyGamer UF2 from SD-save branch
- Target hardware: Adafruit PyGamer M4
- Language: Ada
- Main project file: `motherlode.gpr`
- Alire manifest: `alire.toml`
- CI workflow: `.github/workflows/build-pygamer-uf2.yml`

Recommended remotes:

```bash
git remote -v
git remote add upstream https://github.com/Fabien-Chouteau/motherlode.git
```

Do not add `upstream` again if it already exists.

## Current Objective

Add persistent game-state saving and high scores using a 4 GB microSD card in the PyGamer while preserving the original game's behavior when no usable card is present.

The finished modification should support:

- Continue an existing game.
- Save player position, money, fuel, cargo, equipment, depth, and mine state.
- Persistent high scores.
- Power-loss-safe alternating save slots.
- A pause/save menu and updated title screen.
- A tested release UF2 that can be copied to `PYGAMERBOOT`.

## Current Status

**Last updated:** 2026-07-04 00:58 MDT

**Phase:** Stock firmware build restored. Design is complete, but SD save gameplay code has not started.

### Completed

- Fork created at `jdburgie/motherlode`.
- Development branch created: `feature/sd-save-highscores`.
- Save-system architecture documented in `docs/SD_SAVE_DESIGN.md`.
- Portable project journal added and linked from the README.
- Reproducible Alire manifest added with pinned 2020-era dependencies.
- GitHub Actions workflow added to build an ELF, convert it to UF2, and upload artifacts.
- Build diagnostics are uploaded even when compilation fails.
- Draft PR `#1` opened so pull-request workflow runs and logs can be inspected.
- CI now builds the stock game from this branch and uploads a UF2 artifact.
- Latest successful CI run: `28698499607`.
- Latest artifact source commit: `eb389ac53eb790f1243cd34db88103f86c77e43e`.
- Latest UF2 artifact checksum: `af6db71daf83751ca0e814ee90603a6c186f011964d6aac63486b8d1b571a38f`.
- The PyGamer USB bootloader was reached after double-tapping Reset. No new firmware was flashed.

### Not completed

- No Ada gameplay source has been changed for persistence.
- SD SPI initialization and FAT mounting have not been implemented.
- No simulator test, hardware test, or power-loss test has been performed.
- The current branch still behaves like stock Motherlode because persistence is not implemented yet.

## Immediate Blocker

No build blocker remains for the stock game. The current blocker for the feature is implementation: persistent save state, SD-card block/FAT access, menus, high scores, and hardware validation have not been written yet.

## Next Exact Task

Flash `dist/motherlode-sd-save-highscores.uf2` to the PyGamer and smoke-test the stock game. If it runs acceptably with the synchronous screen refresh path, begin Stage 1 by adding portable player/world state interfaces.

## Reproducible Build Inputs

The current `alire.toml` pins:

```text
pygamer_bsp = 0.1.0
geste        = 1.0.0
virtapu      = 0.1.1
gnat_arm_elf = 10.3.1
gprbuild     = 21.0.2
```

Resolved transitive dependencies observed in CI:

```text
cortex_m   = 0.3.0
hal        = 0.4.0
samd51_hal = 0.1.0
```

The current build command is:

```bash
alr build -- -XMOTHERLODE_BUILD=Production -cargs:Ada -gnatX
```

The original repository's UF2 conversion process is:

```bash
arm-eabi-objcopy -O binary obj_target/motherlode.elf obj_target/motherlode.bin
python3 uf2conv.py -b 0x4000 -c -o motherlode.uf2 obj_target/motherlode.bin
```

The old script used Python 2. The CI workflow has been modernized to use Python 3.

## Build Reconstruction Notes

This section records the practical path from a non-building source branch to a CI-produced UF2. Keep it intact unless the build process is replaced by a simpler known-good path.

### Important outcome

The branch now builds a flashable firmware artifact in GitHub Actions, but the firmware is still stock gameplay. Getting the build green did not implement SD save/load support.

Latest known-good CI build:

```text
Workflow: Build PyGamer UF2
Run:      28698499607
Commit:   eb389ac53eb790f1243cd34db88103f86c77e43e
Artifact: motherlode-sd-save-highscores-uf2
UF2:      motherlode-sd-save-highscores.uf2
SHA-256:  af6db71daf83751ca0e814ee90603a6c186f011964d6aac63486b8d1b571a38f
```

The same firmware bytes were produced at `0e24821`; the later `eb389ac` run only adds journal documentation, so the binary checksum stayed unchanged.

### Local machine limitation

The local macOS workspace did not have `alr` or `gprbuild` on `PATH`, so the reliable build environment was GitHub Actions. Local checks used Git, shell inspection, and downloaded CI artifacts. Do not assume local `alr build` works until Alire and the ARM GNAT toolchain are installed locally.

Useful local checks:

```bash
which alr
which gprbuild
git status --short --branch
git diff --check
gh run list --branch feature/sd-save-highscores --limit 5
gh run view <run-id> --log-failed
gh run download <run-id> -n motherlode-build-diagnostics -D /private/tmp/motherlode-diagnostics-<run-id>
gh run download <run-id> -n motherlode-sd-save-highscores-uf2 -D dist-<commit>
```

### Dependency pins that worked

The first Alire manifest used `gprbuild = "*"`, which selected the system GPRbuild package on Ubuntu. That failed before compiling Motherlode because GPRbuild could not match the ARM Ada compiler, target, and `zfp-cortex-m4f` runtime.

The working manifest pins packaged GPRbuild:

```toml
[[depends-on]]
pygamer_bsp = "=0.1.0"
geste = "=1.0.0"
virtapu = "=0.1.1"
gnat_arm_elf = "=10.3.1"
gprbuild = "=21.0.2"
```

Do not casually bump these versions while implementing saves. If a dependency must change, first prove the stock game still builds and records a UF2 checksum.

### Failure chain and fixes

1. **Toolchain discovery failed with system GPRbuild.**

   Symptom:

   ```text
   gprconfig: can't find a toolchain for language 'ada', target 'arm-eabi', runtime 'zfp-cortex-m4f'
   ```

   Diagnostic findings:

   - `arm-eabi-gcc` existed in the Alire toolchain.
   - The `zfp-cortex-m4f` runtime directory existed.
   - `arm-elf-gcc` did not exist.
   - Patching the BSP target from `arm-eabi` to `arm-elf` only changed the failing label and did not fix discovery.

   Fix:

   - Pin `gprbuild = "=21.0.2"` in `alire.toml`.
   - Remove the temporary workflow step that edited `pygamer_bsp.gpr`.

2. **Motherlode expected a newer PyGamer screen API than the pinned BSP provided.**

   Symptom:

   ```text
   render.ads: "Framebuffer_Access" not declared in "Screen"
   ```

   Cause:

   - The project code used `Screen.Framebuffer_Access`.
   - The pinned Alire `pygamer_bsp = 0.1.0` package does not expose that access type.

   Fix:

   - Add a local `Render.Frame_Buffer_Access` type.
   - Declare `FB1` and `FB2` as aliased `Frame_Buffer` objects.
   - Make `Refresh_Screen` accept `Render.Frame_Buffer_Access`.

3. **The attempted DMA refresh path was not available in the pinned BSP.**

   Symptom:

   ```text
   render.adb: "Wait_End_Of_DMA" not declared in "Screen"
   render.adb: "Start_DMA" not declared in "Screen"
   ```

   Cause:

   - The `pygamer_bsp = 0.1.0` API has `Push_Pixels`, not the later DMA helpers.

   Fix:

   - Change `Refresh_Screen` to:

   ```ada
   Screen.Set_Address (X_Start => 0,
                       X_End   => Screen.Width - 1,
                       Y_Start => 0,
                       Y_End   => Screen.Height - 1);

   Screen.Start_Pixel_TX;
   Screen.Push_Pixels (Acc.all);
   Screen.End_Pixel_TX;
   ```

   Hardware risk:

   - This is a synchronous screen update path. It may be slower than the original intended DMA path and must be smoke-tested on the PyGamer before feature work proceeds too far.

4. **A dependency used an Ada 202x feature.**

   Symptom:

   ```text
   sam-sercom-spi.adb: delta_aggregate is an Ada 202x feature
   compile with -gnatX
   ```

   Fix:

   - Add `-cargs:Ada -gnatX` to the CI build command:

   ```bash
   alr build -- -XMOTHERLODE_BUILD=Production -cargs:Ada -gnatX
   ```

5. **UF2 conversion failed because the modern converter needs family metadata.**

   Symptom:

   ```text
   FileNotFoundError: uf2families.json
   ```

   Cause:

   - The workflow downloaded only `uf2conv.py` from the current Microsoft UF2 repo.
   - The current converter loads `uf2families.json` from the same directory.

   Fix:

   - Download both files before conversion:

   ```bash
   curl --fail --location --silent --show-error \
     --output uf2conv.py \
     https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py
   curl --fail --location --silent --show-error \
     --output uf2families.json \
     https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2families.json
   ```

### Working CI build and packaging sequence

The workflow's successful firmware path is:

```bash
alr --version
alr update
alr printenv
alr build -- -XMOTHERLODE_BUILD=Production -cargs:Ada -gnatX
test -f obj_target/motherlode.elf

alr exec -- bash -lc '
  set -euo pipefail
  OBJCOPY="$(command -v arm-eabi-objcopy || command -v arm-none-eabi-objcopy || command -v arm-elf-objcopy)"
  "${OBJCOPY}" -O binary obj_target/motherlode.elf dist/motherlode-sd-save-highscores.bin
'

python3 uf2conv.py \
  -b 0x4000 \
  -c \
  -o dist/motherlode-sd-save-highscores.uf2 \
  dist/motherlode-sd-save-highscores.bin
```

The `-b 0x4000` base address follows the original repository's conversion process and matches the PyGamer bootloader reservation.

### Artifact contents

Successful firmware artifacts contain:

```text
motherlode-sd-save-highscores.bin
motherlode-sd-save-highscores.elf
motherlode-sd-save-highscores.uf2
SHA256SUMS.txt
SOURCE_COMMIT.txt
```

Downloaded artifacts are intentionally left untracked in local folders such as `dist/` or `dist-eb389ac/`. Do not commit firmware binaries unless there is an explicit release-artifact decision.

### What to verify on hardware

Before starting SD-save implementation, flash the current UF2 and check:

- The title screen appears.
- Joystick/menu controls respond.
- The game starts.
- The pod moves and drills.
- Cargo/store/equipment screens still render.
- Audio still works.
- Frame rate is acceptable with synchronous `Push_Pixels`.
- The PyGamer reboots cleanly after copying the UF2 to `PYGAMERBOOT`.

If the display is too slow or visibly broken, revisit the BSP/API choice before writing save logic. A tempting path is to move to a newer PyGamer BSP with DMA helpers, but that must be done as its own build-restoration task with the stock game kept green.

## Build Workflow Behavior

The workflow currently:

1. Checks out the branch.
2. Installs Alire using `alire-project/setup-alire@v6`.
3. Resolves pinned dependencies and records the environment.
4. Inventories compiler binaries, targets, and runtime directories.
5. Builds Production firmware with `-gnatX` enabled for dependency compatibility.
6. Converts the ELF to BIN with `arm-eabi-objcopy`.
7. Downloads `uf2conv.py` and `uf2families.json`.
8. Converts the BIN to UF2.
9. Uploads firmware artifacts on success.
10. Uploads diagnostic logs even on failure.

## GitHub Actions Attempts

### Run 3, workflow run `28696644132`

- Checkout: success
- Alire installation: success
- Dependency resolution: success
- Production build: failed
- UF2 conversion: skipped
- Main finding: GPRbuild could not find Ada toolchain for `arm-eabi` and `zfp-cortex-m4f`.

### Run 5, workflow run `28696699101`

- Added persistent diagnostic artifacts.
- Dependency resolution: success
- Production build: failed
- Diagnostic artifact uploaded: `motherlode-build-diagnostics`
- Confirmed the failure occurs during compiler/toolchain selection.

### Run 7, workflow run `28696738167`

- Added ARM toolchain inventory.
- Dependency resolution: success
- Toolchain inventory: success
- Production build: failed
- Confirmed `arm-eabi-gcc` and the `zfp-cortex-m4f` runtime directory are installed.
- Confirmed no `arm-elf-gcc` executable exists.

### Run 9, workflow run `28696789097`

- Temporarily patched BSP target from `arm-eabi` to `arm-elf`.
- Patch step: success
- Toolchain inventory: success
- Production build: failed
- Error moved from target `arm-eabi` to target `arm-elf`, proving the label patch alone does not solve discovery.

### Run 20, workflow run `28698247768`

- Checkout: success
- Alire installation: success
- Dependency resolution: success
- Production build: success
- UF2 conversion: success
- Firmware artifact uploaded: `motherlode-sd-save-highscores-uf2`
- UF2 checksum: `af6db71daf83751ca0e814ee90603a6c186f011964d6aac63486b8d1b571a38f`

## Commits Created During This Work

```text
d126e06  Document SD save and high-score design
28ff779  Add portable project journal and resume guide
83f0c7f  Link project journal from README
4d6099c  Fix journal template and record repository breadcrumbs
2a58b75  Add reproducible Alire build manifest
9631c9c  Add GitHub Actions PyGamer UF2 build
46321cc  Run firmware build for pull requests
9f899a2  Preserve firmware build diagnostics
d01b7d9  Inventory ARM cross-toolchain in CI
a275817  Apply GPR arm-elf compatibility alias
43dbfa7  Journal build investigation and CI attempts
e645445  Try packaged GPRbuild for PyGamer CI
a80ad52  Adapt framebuffer refresh to PyGamer BSP
54a4c3c  Use synchronous PyGamer screen refresh
eebe8ad  Enable Ada 202x extensions in firmware CI
0e24821  Download UF2 family metadata in CI
```

This journal update is the next commit after those entries.

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
- Store fuel as integer thousandths rather than as raw floating point.
- Store each world cell as one explicit byte.

### Player restoration

Loading must reconstruct runtime state rather than restore opaque memory:

- Position restored and validated.
- Speed reset to zero.
- Cargo total recalculated.
- Vehicle mass recalculated.
- Drill animation and movement flags cleared.
- Fuel, cargo, equipment, and coordinates clamped to valid ranges.

### Autosave policy

Autosave only at safe checkpoints:

- After cargo is sold.
- After an equipment purchase.
- After refueling.
- During Save and Quit.

Do not write continuously during the frame loop.

## Hardware Notes

The built-in microSD interface uses a separate SPI controller from the display.

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

The mine contains 18,000 cells. One persisted byte per cell requires approximately 18 KB per world payload.

PyGamer bootloader procedure:

1. Connect a known-good USB data cable.
2. Turn on the PyGamer.
3. Double-tap Reset.
4. Confirm the `PYGAMERBOOT` drive appears.
5. Copy the tested UF2 to that drive.

Powering up alone does not prove a cable carries USB data.

## Implementation Roadmap

### Stage 0: Reproduce the original build

Status: **CI complete; hardware smoke test pending**

- [x] Identify likely historical dependencies.
- [x] Add an Alire manifest.
- [x] Add a CI builder.
- [x] Locate and modernize the UF2 conversion sequence.
- [x] Capture compiler diagnostics.
- [x] Correct GPRbuild/compiler/runtime discovery.
- [x] Produce the original ELF from the branch.
- [x] Produce a UF2 artifact.
- [x] Record flash and RAM use through the CI build log.
- [ ] Flash and smoke-test on the PyGamer.

### Stage 1: Portable in-memory state

- Add `Player_Save_State`.
- Add `Export_State` and `Import_State`.
- Add `Maximum_Depth` and `Net_Worth`.
- Add explicit world-cell encoding and decoding helpers.

### Stage 2: Serialization core

- Explicit byte writer and reader helpers.
- Save header encoder and decoder.
- CRC-32.
- Strict validation for damaged or future-version files.
- In-memory round-trip tests where possible.

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
- Preserve the previous slot until the new save is fully flushed.
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

Provisional score:

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

Then publish a tested UF2.

## Known Risks

- The PyGamer Ada BSP does not expose an obvious ready-made SD-card package.
- FAT support and an SD protocol layer may increase firmware size significantly.
- The PyGamer project has roughly 496 KB of application flash after bootloader reservation.
- The current gameplay loop does not naturally return to the title screen.
- The original game has no formal game-over condition.
- Save compatibility must be explicit from the first release.
- The original embedded build stack is old enough that compiler and GPRbuild version matching matters.

## Working Rules

1. Work only on `feature/sd-save-highscores` unless intentionally creating a narrower branch.
2. Keep commits small and testable.
3. Do not mix broad formatting changes with functional changes.
4. Update this journal before ending every session.
5. Record commands that actually ran.
6. Record hardware, card format, test result, and visible symptoms.
7. Push completed work before leaving a computer station.
8. Never commit credentials, tokens, or personal card images.
9. Do not claim a UF2 exists until CI uploads one and its checksum is recorded.

## End-of-Session Checklist

```bash
git status
git diff --check
git log --oneline --decorate -10
```

Then:

- Run the most relevant build or tests.
- Commit intended changes.
- Push the branch.
- Update Current Status, Immediate Blocker, Next Exact Task, and Session Log.
- Name the exact next file and edit.

## Session Log

### 2026-07-04, stock firmware UF2 build restored

**Starting point**

- Branch: `feature/sd-save-highscores`
- Starting commit: `43dbfa7`
- Machine/OS: local Codex workspace plus GitHub Actions on Ubuntu 22.04
- Hardware connected: not tested in this session

**Completed**

- Confirmed branch contained documentation/build work only; SD save gameplay code had not started.
- Pinned Alire-packaged `gprbuild = "=21.0.2"`.
- Removed the temporary workflow patch that rewrote the BSP target to `arm-elf`.
- Adapted Motherlode rendering to the older Alire PyGamer BSP screen API.
- Enabled `-gnatX` for dependency code that uses an Ada 202x feature.
- Downloaded `uf2families.json` alongside `uf2conv.py`.
- Produced and downloaded a CI-built UF2 artifact.

**Files changed**

- `alire.toml`: pinned packaged GPRbuild.
- `.github/workflows/build-pygamer-uf2.yml`: removed target patch, added `-gnatX`, downloaded UF2 metadata.
- `src/render.ads`: added local framebuffer access type.
- `src/render.adb`: switched screen refresh to synchronous `Push_Pixels`.
- `PROJECT_JOURNAL.md`: recorded the successful build.

**Tests and results**

- GitHub Actions run `28698247768`: success.
- Produced `dist/motherlode-sd-save-highscores.uf2`.
- UF2 SHA-256: `af6db71daf83751ca0e814ee90603a6c186f011964d6aac63486b8d1b571a38f`.
- No hardware smoke test performed yet.

**Commits pushed**

- `e645445` Try packaged GPRbuild for PyGamer CI
- `a80ad52` Adapt framebuffer refresh to PyGamer BSP
- `54a4c3c` Use synchronous PyGamer screen refresh
- `eebe8ad` Enable Ada 202x extensions in firmware CI
- `0e24821` Download UF2 family metadata in CI

**Problems or unresolved questions**

- The produced firmware is stock gameplay from this branch, not an SD-save implementation.
- The synchronous screen refresh path may perform differently than the original DMA-based render path and needs hardware testing.

**Next exact action**

- Flash `dist/motherlode-sd-save-highscores.uf2` to the PyGamer and smoke-test display, controls, audio, and gameplay before starting Stage 1 state export/import work.

### 2026-07-03, build reconstruction and UF2 pipeline

**Starting point**

- Branch: `feature/sd-save-highscores`
- Starting functional state: stock Motherlode game, documentation-only SD save branch
- Work environment: GitHub-connected tools plus GitHub Actions on Ubuntu 22.04
- Hardware: PyGamer available; bootloader reached after double-tapping Reset

**Completed**

- Confirmed that the requested branch ZIP was source code, not a flashable UF2.
- Located the original `convert_to_uf2.sh` process.
- Added `alire.toml` with pinned historical dependencies.
- Added GitHub Actions firmware build and artifact packaging.
- Added pull-request triggering and opened draft PR `#1`.
- Added diagnostic artifact upload on failed builds.
- Added compiler, target, and runtime inventory.
- Tried both the BSP's original `arm-eabi` target and a temporary `arm-elf` compatibility edit.
- Downloaded and inspected multiple build-diagnostic artifacts.

**Tests and results**

- Alire installation succeeds.
- Dependency resolution succeeds.
- `arm-eabi-gcc` is installed.
- `zfp-cortex-m4f` runtime directory is installed.
- GPRbuild fails before compiling Motherlode source because it cannot match the Ada compiler, target, and runtime.
- No ELF, BIN, or UF2 was produced.
- No firmware was copied to the PyGamer.

**Problems or unresolved questions**

- Why the selected system GPRbuild cannot discover the installed `arm-eabi` GNAT configuration.
- Which packaged GPRbuild version best matches GNAT ARM 10.3.1 and the old BSP.
- Whether a generated GPR configuration file will be needed after switching GPRbuild.

**Next exact action**

- Edit `alire.toml` to pin an Alire-packaged GPRbuild, remove the temporary `arm-elf` patch from `.github/workflows/build-pygamer-uf2.yml`, and rerun CI with the original `arm-eabi` target.

### 2026-07-03, repository setup and architecture

**Completed**

- Forked `Fabien-Chouteau/motherlode` to `jdburgie/motherlode`.
- Created `feature/sd-save-highscores` from `master`.
- Inspected player, world, main loop, and title-screen architecture.
- Confirmed relevant PyGamer SD pins and separate screen/SD SPI controllers.
- Added `docs/SD_SAVE_DESIGN.md`.
- Added and linked this project journal.

**Tests**

- Repository permissions and branch creation verified through GitHub.
- No firmware build or hardware test performed in this first session.

**Next action at that time**

- Reproduce the original clean build before implementing persistence.

## New Session Entry Template

````markdown
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
````
