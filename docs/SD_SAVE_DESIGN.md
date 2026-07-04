# Motherlode SD Save and High-Score Design

This branch adds persistent game state and high scores for the Adafruit PyGamer's microSD slot.

## Goals

- Load and save the current mine, player state, cargo, fuel, money, upgrades, and position.
- Preserve high scores independently from the current game.
- Survive interrupted writes by alternating between two save slots.
- Keep the original game playable when no SD card is inserted.
- Avoid serializing internal physics-engine objects directly.

## SD card assumptions

- MBR partition table.
- First partition formatted as FAT32.
- Save directory: `/MOTHERLD/`.
- PyGamer SD interface: SERCOM1 SPI, chip-select PA14.

## Files

- `/MOTHERLD/SAVEA.DAT`
- `/MOTHERLD/SAVEB.DAT`
- `/MOTHERLD/SCOREA.DAT`
- `/MOTHERLD/SCOREB.DAT`

The game loads the valid copy with the highest generation number.

## Save header

All multibyte values use little-endian encoding.

| Field | Size | Description |
|---|---:|---|
| Magic | 4 | ASCII `MLOD` |
| Format version | 2 | Initially `1` |
| Header size | 2 | Allows future extension |
| Generation | 4 | Incremented for every successful save |
| Payload size | 4 | Number of payload bytes |
| Payload CRC-32 | 4 | CRC of payload only |
| Run ID | 4 | Identifies one playthrough |
| Reserved | 8 | Zero in version 1 |

## Player payload

The portable player record contains only explicit game values:

- X and Y position
- Money
- Fuel in thousandths of a unit
- Quantity of coal, iron, gold, and diamond
- Engine, cargo, tank, and drill levels
- Maximum depth reached

On load, runtime-only state is reconstructed:

- Speed is reset to zero.
- Cargo total and vehicle mass are recalculated.
- Movement and drill-animation flags are cleared.
- Position, fuel, cargo, and upgrade levels are range checked.

## World payload

The mine contains 30 x 600 cells. Each cell is stored as one byte using the explicit values:

| Value | Cell |
|---:|---|
| 0 | Empty |
| 1 | Dirt |
| 2 | Rock |
| 3 | Coal |
| 4 | Iron |
| 5 | Gold |
| 6 | Diamond |

This uses 18,000 bytes and avoids relying on Ada compiler record representation.

## Safe-write sequence

1. Determine the newest valid slot.
2. Select the other slot as the destination.
3. Create or truncate the destination file.
4. Write a provisional header with an invalid CRC.
5. Write the complete payload.
6. Flush the file.
7. Seek to the beginning and write the final header and CRC.
8. Flush and close.

If power fails during the operation, the previous slot remains loadable.

## High scores

Version 1 stores up to ten entries. Each entry contains:

- Run ID
- Composite score
- Maximum depth
- Highest cash balance
- Net worth

Suggested composite score:

`money + purchased-upgrade value + maximum-depth-in-cells * 100`

## Planned interface changes

### Player

- `Export_State`
- `Import_State`
- `Maximum_Depth`
- `Net_Worth`

### World

- `Export_Cell`
- `Import_Cell`
- Validation helpers for persisted cell values

### Motherload

- Start a new game or continue a loaded game.
- Pause menu and explicit save action.
- Autosave after safe economic checkpoints.

### Title screen

- Continue
- New Game
- High Scores
- Credits

`Continue` is unavailable when no valid save is present.

## Implementation stages

1. Add portable player/world state interfaces without changing gameplay.
2. Add CRC-32 and in-memory serialization tests in the simulator build.
3. Add the PyGamer SPI SD block driver.
4. Mount FAT and implement alternating save slots.
5. Add title and pause menus.
6. Add high-score persistence.
7. Build a release UF2 and test power-loss recovery on hardware.
