# Cave / Gazelle Board Research

This note collects non-MAME references to keep the MiSTer implementation from
depending on MAME alone. MAME is still useful for executable behavior, but board
families should be cross-checked against manuals, PCB photos, preservation
pages, and collector notes whenever possible.

## Source Log

| Source | Usefulness |
| --- | --- |
| Arcade-History, Air Gallet detail page: https://www.arcade-history.com/?id=50&n=airgallet&page=detail | External confirmation of Air Gallet metadata, screen orientation, CPU/audio hardware, EEPROM, and board ID. |
| Arcade Database, Air Gallet: https://adb.arcadeitalia.net/dettaglio_mame.php?game_name=agallet | External confirmation of Air Gallet parent set, board ID `BP962A`, MC68000/Z80/YM2151/OKI hardware, and timing/visible-area data. |
| Arcade-Projects, Air Gallet conversion thread: https://www.arcade-projects.com/threads/air-gallet-conversion.24500/ | PCB-level collector notes. Useful because the thread compares real Air Gallet, Sailor Moon, and Metamoqester boards and calls out which chips/ROM positions differ. |
| Arcade-Projects, Air/Sailor/Metamoqester hardware thread: https://www.arcade-projects.com/threads/possible-conversion-3in1-multi-on-banpresto-titles-air-gallet-salior-moon-metamoqester.9838/ | Collector comparison of BP947A/BP945A/BP962A boards and shared custom-chip family. |
| Metal Game Solid, Air Gallet MiSTer note: https://metalgamesolid.com/fpga/mister-fpga/air-gallet-now-playable-on-misterfpga/ | Secondary report on the Coin-Op Collection Air Gallet bring-up: memory checks, interrupt handling, and 6bpp layer rendering were called out as required work. |
| Coin-Op Collection Air Gallet update: https://www.patreon.com/posts/coin-op-presents-135641029 | Practical FPGA bring-up notes: post-check memory/protection behavior, unusual interrupt setup, Sailor Moon-shared tile/sprite behavior, layer 2 6bpp, and inverted framebuffer/sprite call behavior. |
| Cave-STG: https://cave-stg.com/ | Community/preservation context for Cave game families and release history. Useful for game-family grouping, less useful for register-level hardware. |
| CAVE database by Buffi: https://cave.buffis.com/ | Community PCB/game catalog. Useful as a checklist for supported and candidate game sets. |

## Air Gallet / Sailor Moon Family

Air Gallet is the immediate bring-up target. The outside references agree on
these board facts:

- Board ID: `BP962A`.
- Main CPU: Motorola MC68000 at 16 MHz.
- Sound CPU: Z80.
- Sound chips: YM2151 plus OKI M6295-class sample playback.
- Nonvolatile memory: 93C46 EEPROM.
- Orientation: vertical for Air Gallet.
- Air Gallet is distributed under Gazelle / Banpresto license branding.

The Arcade-Projects conversion notes are important for next-game planning:

- Air Gallet and Pretty Soldier Sailor Moon appear to be the closest pair in
  this subfamily.
- The Arcade-Projects thread lists Metamoqester as `BP947A`, Sailor Moon as
  `BP945A`, and Air Gallet as `BP962A`, all with tilemap custom
  `038 9437WX711`, sprite custom `013 9346E7002`, and Z80 sound.
- Metamoqester / The Ninja Master uses related custom chips but has a more
  different PCB layout and ROM organization, so it should not be treated as a
  drop-in Air/Sailor sibling.
- The thread identifies PAL/protection/conversion details as practical risks.
  We should avoid relying on patched ROMs or conversion-only data. Any
  transform/protection behavior needed by stock ROMs belongs in core HDL.

Implementation implications:

- Keep Air Gallet in its own main map and avoid folding it into the older
  generated `Main.sv` map chain.
- Treat Sailor Moon as likely sharing the Air Gallet/Z80/two-OKI sound shape,
  but do not assume every address alias or graphics callback is identical.
- Treat Air Gallet and Sailor Moon as candidates for a shared Air/Sailor board
  personality module after Air boots, with separate maps/quirks layered on top.
- Preserve room for board-specific PAL/protection behavior in an Air/Sailor
  board module rather than hiding it in global glue.
- The faster Z80 warning from prior developer experience remains credible for
  Air/Sailor. Z80 ROM wait/ready or clock-enable throttling should stay on the
  debug list if sound-side execution goes unstable.
- A public Coin-Op Collection progress post says their Air Gallet work needed
  post-check memory/protection handling, unusual interrupt handling, layer 2
  6bpp rendering, and an inverted framebuffer/sprite call compared with
  Mazinger Z. Those are strong leads for our current black-screen and later
  graphics/sprite phases.

## Other Nearby Families

### Metamoqester / The Ninja Master

Collector notes indicate related Cave/Banpresto custom silicon, but a different
layout from Air Gallet and Sailor Moon. This should be handled as its own map
family if added later.

### DonPachi / DoDonPachi / Dangun / ESP Ra.De. / Puzzle Uo Poko / Guwange

These are Cave-labeled first-generation games already represented in the
existing core shape. They are useful regression references while Air/Sailor work
continues, but they should not drive Air Gallet's map design.

Implementation implications:

- Do not optimize Air Gallet by assuming the existing YMZ280B/no-Z80 games have
  the same sound-memory pressure profile.
- Continue keeping board profile decisions explicit: sound CPU style, sample
  chip count, tile-layer format, sprite format, rotation, and ROM packing.

## Air Gallet Bring-Up Leads

Current black-screen work should prioritize:

1. Main IRQ cause behavior. Air Gallet needs read-to-clear IRQ-cause side
   effects at the `b80000` register block.
2. Post-check memory/protection behavior. External FPGA bring-up notes say Air
   Gallet checks four extra bytes even though that memory is not otherwise
   used. We must implement the behavior core-side, not patch ROMs.
3. Unmapped/exception-path debug. If the CPU falls to top-of-address-space
   vectors, capture last CPU bus address and control lines, not just the last
   program-ROM read address.
4. Stock-ROM protection/PAL behavior. If the CPU reaches a protection query
   and loops or jumps away, implement the behavior core-side.
5. Z80 sound ROM stability. If the main CPU gets past boot and the Z80 starts
   misbehaving, test an Air-only ROM-read wait/ready path before touching
   shared sound chips.
6. Graphics banking. Layer 2 and banked tile-code behavior should be verified
   against stock ROMs, not closed-core patched graphics data.
7. Framebuffer/sprite swap behavior. External FPGA bring-up notes say Air uses
   the Mazinger-like framebuffer setup with the relevant call inverted, and
   getting this wrong can suppress sprites.

Latest bring-up read after the IRQ-clear experiment:

- Still black screen.
- `PostPC` showed `RPL:10`, `STA:CD`, last program address around `00:5B:0x`,
  and first unmapped address `FF:9C:9E`.
- `CPU Addr` and `Pipeline` still show real program/IRQ/palette activity before
  the bad address.

Next source change under test:

- Air Gallet's extra work/post-check RAM windows are no longer aliased into the
  main RAM port.
- For this diagnostic build they read as zero and writes are ignored. This
  matches the MAME/FPGA-bring-up clue that these post-check bytes behave like
  freshly initialized scratch/protection RAM rather than the normal 0x100000
  main RAM.
- If this improves boot, replace the zero model with proper Air-only retained
  secondary/tiny work RAM so later code can read back its own writes.

Result from the zero-model test:

- Still no picture, but `PostPC` improved substantially: `STA:7D` and
  `ADH/ADM/ADL = 00/00/00`.
- That means the open-bus/fault condition disappeared; the CPU is running
  through program space instead of dying at an unmapped address.

Next source change under test:

- Added a retained Air-only work RAM in `Main.sv`.
- `AirGalletMainDecoder.sv` now maps the Air work/post-check windows into that
  private RAM instead of the shared main RAM:
  `0x400000-0x407fff`, `0x40c000-0x40ffff`, and the tiny `0x110000`,
  `0x410000`, `0x510000`, and `0x908000` windows.
- This is the non-diagnostic form of the previous zero-model fix. If the CPU
  was waiting on a value it wrote into those scratch/protection locations, this
  should let it advance.

## Open Research To Collect

- Air Gallet operator manual or DIP sheet with board wiring and switch tables.
- High-resolution photos of an original, non-conversion Air Gallet PCB, both
  component and solder sides.
- Pretty Soldier Sailor Moon operator manual and PCB photos.
- Any schematics or PAL equations for BP945A/BP962A-era Banpresto/Gazelle
  boards.
- Confirmation of whether both OKI chips are physically populated and how their
  banking pins are wired on original Air Gallet boards.
