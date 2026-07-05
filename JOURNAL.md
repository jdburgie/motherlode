# Motherlode Engineering Journal

## 2026-07-04: Reconstructing a reproducible PyGamer build

### Outcome

Motherlode now builds successfully on Windows from the `fix/self-contained-build` branch using pinned source dependencies and the repository build script.

The successful local build was reported from:

```text
C:\Users\jdbur\Github\motherlode
```

The build produces these files:

```text
obj_target/motherlode.elf
build/motherlode.bin
build/motherlode.uf2
```

The UF2 image is generated for the SAMD51 family with a base address of `0x4000`, matching the PyGamer bootloader/application layout.

---

## Final Windows build procedure

Use a recursive Git checkout. GitHub's **Download ZIP** option does not include Git submodule contents.

```powershell
git clone --branch fix/self-contained-build --recurse-submodules `
    https://github.com/jdburgie/motherlode.git

cd motherlode
```

For an existing checkout:

```powershell
git checkout fix/self-contained-build
git pull
git submodule sync --recursive
git submodule update --init --recursive
```

Required commands on `PATH`:

```powershell
gprbuild --version
arm-eabi-gcc --version
arm-eabi-objcopy --version
python --version
git --version
```

The working compiler setup used the Alire-provided ARM cross-compiler package:

```powershell
alr install gprbuild gnat_arm_elf=10.3.1
```

Run the build:

```powershell
.\scripts\build.ps1 -Checks Disabled
```

To capture the full build transcript:

```powershell
.\scripts\build.ps1 -Checks Disabled 2>&1 |
    Tee-Object .\build.log
```

The script performs all of the following:

1. Verifies required host commands.
2. Synchronizes and initializes all Git submodules.
3. Verifies every dependency commit against the lock list.
4. Constructs `GPR_PROJECT_PATH` from the vendored projects.
5. Builds the ARM ELF using GPRbuild.
6. Enables GNAT extended/Ada 2022 syntax with `-gnatX`.
7. Converts the ELF to a raw binary using `arm-eabi-objcopy`.
8. Converts the binary to UF2 using the pinned Microsoft UF2 utility.

---

## Pinned dependencies

All project source dependencies are included as Git submodules under `vendor/` and pinned to exact commits.

| Dependency | Repository path | Pinned commit |
|---|---|---|
| PyGamer BSP | `vendor/pygamer-bsp` | `2dba1dd3a9d9e8d5d5e441bdac37242a56ae048d` |
| SAMD51 HAL | `vendor/samd51-hal` | `3edd815bab9a8a4df15bd459f679a2465a9208ac` |
| Cortex-M support | `vendor/cortex-m` | `8c24b76979aa7fb86019006111007f4272dfe89c` |
| HAL | `vendor/hal` | `92eb1f60b352230352c41137b6983d0bb5e1b7ff` |
| GESTE | `vendor/geste` | `9e99f066c49b3fccd02420b899d8ef95eeb0eb1b` |
| VirtAPU | `vendor/virtapu` | `bc5b7bf6cace9637208662e0dafb0b5c72b603f6` |
| Microsoft UF2 tools | `vendor/uf2` | `90e9741f217f5a40c98ba74d663e408041037578` |

The machine-specific compiler, GPRbuild executable, Python interpreter, and Git executable are intentionally not committed to the repository.

The complete dependency record is also maintained in `DEPENDENCIES.lock`.

---

## Repository project wiring

`motherlode.gpr` was changed to reference the repository copies directly rather than relying on globally installed Ada projects:

```ada
with "vendor/hal/hal.gpr";
with "vendor/cortex-m/cortex_m4f.gpr";
with "vendor/samd51-hal/ATSAMD51J19A.gpr";
with "vendor/pygamer-bsp/pygamer_bsp.gpr";
with "vendor/virtapu/virtapu.gpr";

project Motherlode extends "vendor/geste/geste.gpr" is
```

This makes the source dependency graph repeatable and prevents the build from silently selecting unrelated versions installed elsewhere on the machine.

---

## Problems encountered and what they taught us

### 1. `gprbuild` was not found

Initial failure:

```text
Required command 'gprbuild' was not found on PATH.
```

Cause:

The repository contained application and library sources, but not the Ada build toolchain. Source dependencies and compiler executables are separate concerns.

Resolution:

Install GPRbuild and the ARM GNAT cross-compiler, then ensure their executable directory is on `PATH`.

Useful verification:

```powershell
gprbuild --version
arm-eabi-gcc --version
arm-eabi-objcopy --version
```

Lesson:

A self-contained embedded repository can pin all source code, but still needs a documented host toolchain contract.

---

### 2. The first `world.adb` rewrite did not compile cleanly with the chosen GNAT generation

The terrain generator had genuine defects in the original code:

- Weighted ranges overlapped at their inclusive boundaries.
- A zero-weight cell could still be selected at a boundary.
- Neighbor bonuses read right and lower cells that had not yet been generated.
- The lower-neighbor branch accidentally read `CY - 1` again.
- Regeneration did not explicitly clear the ground first.

The first repair used a new integer random helper. That change introduced avoidable compiler compatibility friction.

Final resolution:

- Restore the original float-producing random generator.
- Keep the corrected cumulative weighted selection.
- Clamp the rare maximum result to `Total - 1`.
- Only use already-generated left and upper neighbors.
- Clear `Ground` before generating it.

The corrected selection pattern is conceptually:

```ada
Choice := Natural (Float (Total) * Rand);
if Choice >= Total then
   Choice := Total - 1;
end if;

for Kind in Cell_Kind loop
   Running_Total := Running_Total + Proba (Kind);
   if Choice < Running_Total then
      return Kind;
   end if;
end loop;
```

Lesson:

When modernizing old embedded Ada, fix the algorithm while minimizing unrelated language and runtime changes. Small, conservative patches travel better across old GNAT toolchains.

---

### 3. Motherlode expected a PyGamer screen API that was not present in the pinned BSP

Failure:

```text
render.ads:63:51: "Framebuffer_Access" not declared in "Screen"
```

Further inspection showed that the game expected an older or unpublished API containing:

```ada
Screen.Framebuffer_Access
Screen.Start_DMA
Screen.Wait_End_Of_DMA
```

The pinned PyGamer BSP exposed this public transfer interface instead:

```ada
procedure Push_Pixels (Data : HAL.UInt16_Array);
```

Its implementation still performs the transfer through the SAMD51 DMA controller internally.

Resolution:

- Define `Framebuffer_Access` locally in `Render`.
- Constrain `FB1` and `FB2` to the exact `Frame_Buffer` subtype.
- Replace the stale asynchronous screen calls with:

```ada
Screen.Set_Address (...);
Screen.Start_Pixel_TX;
Screen.Push_Pixels (Acc.all);
Screen.End_Pixel_TX;
```

Lesson:

Do not infer compatibility from package names alone. Embedded libraries often change APIs between nearby commits without formal releases. Pinning must be paired with compilation against the actual public declarations.

---

### 4. PowerShell treated ordinary compiler warnings as terminating errors

Observed output:

```text
geste-maths.adb:77:15: warning: redundant conversion, "A" is of type "Value"
```

The compiler warning was written to stderr. Under Windows PowerShell with:

```powershell
$ErrorActionPreference = 'Stop'
```

that stderr line became a terminating `NativeCommandError`, even though the native process had not necessarily failed.

Resolution:

The PowerShell script now invokes native programs through `Invoke-NativeCommand`, which:

- Temporarily allows native stderr output.
- Captures and prints stdout and stderr.
- Preserves the process exit code.
- Throws only when the native executable returns a nonzero exit code.

Lesson:

For native build tools, stderr does not mean failure. The exit code is authoritative.

---

### 5. The SAMD51 HAL requires Ada 2022 extended syntax

Failure:

```text
sam-sercom-spi.adb:72:09: delta_aggregate is an Ada 202x feature
sam-sercom-spi.adb:72:09: compile with -gnatX
```

Cause:

The pinned SAMD51 HAL uses a delta aggregate. GNAT 10 supports the syntax, but does not enable it in its default language mode.

Resolution:

Pass the option globally through GPRbuild so it applies to the main project and all dependency projects:

```text
-cargs:Ada -gnatX
```

The PowerShell argument list now includes:

```powershell
'-cargs:Ada',
'-gnatX'
```

The Unix build script uses the same options.

Lesson:

Compiler version support and compiler default language mode are not the same thing. A feature can exist in the compiler but remain disabled without an explicit switch.

---

## Build-script behavior worth preserving

### Dependency integrity checks

Before compilation, the scripts compare each submodule's current `HEAD` with its required commit. This prevents accidental builds from dirty, advanced, or detached dependency revisions.

### Native output handling on Windows

Warnings should remain visible, but only a nonzero `$LASTEXITCODE` should terminate the build.

### Incremental builds

A normal rerun does not require deleting `obj_target`. GPRbuild resumes incrementally. Clean builds are useful when project options, runtime selection, or generated configuration changes, but should not be the default ritual.

Optional cleanup:

```powershell
Remove-Item .\obj_target -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\build -Recurse -Force -ErrorAction SilentlyContinue
```

### Useful log extraction

For a future compiler failure:

```powershell
Select-String .\build.log `
    -Pattern "\.ad[bs]:[0-9]+:[0-9]+:|error:|failed with status" `
    -Context 2,2
```

Always preserve the first specific compiler diagnostic. The final line such as `gprbuild failed with exit code 4` is only a summary.

---

## Earlier code-review findings retained in this branch

### Terrain generation

The generation pass proceeds one complete column at a time. During generation, only the left and upper cells are guaranteed to contain generated terrain. Reading right or lower cells biases selection toward stale or `Empty` values.

### Weighted random selection

The original inclusive test:

```ada
if Value in Total .. Total + Proba (Kind) then
```

made neighboring intervals share a boundary and allowed zero-sized intervals to match. Cumulative upper-exclusive selection avoids both defects.

### README provenance

The README now distinguishes this maintained dependency-complete branch from the original upstream project and clearly labels any upstream prebuilt UF2 reference.

---

## Important constraints

- Source dependencies are stored as pinned Git submodules, not copied into the parent repository as ordinary files.
- A recursive clone is required.
- GitHub Download ZIP is not sufficient.
- The compiler/runtime tools remain external host prerequisites.
- The target is `arm-eabi` with the `zfp-cortex-m4f` runtime expected by the project files.
- The target microcontroller is SAMD51, specifically the ATSAMD51J19A project configuration used by the PyGamer BSP.
- UF2 conversion uses family `SAMD51` and base address `0x4000`.

---

## Files introduced or materially changed during reconstruction

```text
.gitignore
.gitmodules
DEPENDENCIES.lock
JOURNAL.md
README.md
motherlode.gpr
scripts/build.ps1
scripts/build.sh
src/render.ads
src/render.adb
src/world.adb
vendor/cortex-m
vendor/geste
vendor/hal
vendor/pygamer-bsp
vendor/samd51-hal
vendor/uf2
vendor/virtapu
```

---

## Final status

The local Windows build completed successfully after the following sequence of corrections:

1. Install and expose GPRbuild and ARM GNAT tools.
2. Pin and initialize all source dependencies.
3. Correct the terrain generation algorithm without over-modernizing it.
4. Adapt rendering to the actual pinned PyGamer BSP screen API.
5. Stop treating native stderr warnings as build failures.
6. Enable Ada 2022 extensions globally with `-gnatX`.

This journal records the path through the brambles so the next build can take the paved road.