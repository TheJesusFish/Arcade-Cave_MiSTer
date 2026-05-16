# Development Notes

## Modernization Pass

Started: 2026-05-14

The project is being moved toward the usual MiSTer root layout:

- `Arcade-Cave.qpf`, `Arcade-Cave.qsf`, `Arcade-Cave.sv`, `Arcade-Cave.sdc`, and `files.qip` live at the repository root.
- `rtl/` contains the core HDL and third-party logic blocks used by the core.
- `sys/` contains the MiSTer framework files.

Do not hand-edit files inside `sys/`. Treat that directory as a framework drop-in. If the framework needs to be updated, replace the folder with a known-good `sys/` from the selected MiSTer template instead of carrying local edits inside it.

The current active Cave logic is the hand-maintained SystemVerilog under `rtl/cave/`. The Chisel source has been moved under `legacy/chisel/` and is retained only as a reference path. Running `make generate-rtl` emits reference HDL into `legacy/generated/cave/`, not into active `rtl/cave/`.

The first piece extracted from the generated Cave HDL is `rtl/cave/CaveGameConfig.sv`. It holds the current supported game constants for ROM offsets, graphics formats, palette banks, sound device routing, and sprite zoom. Future game probes should start there, then move into hardware differences only when the MAME driver shows a board feature this core does not already implement.

The next hand-maintained helper pass converted small, self-contained generated modules without changing their public ports: `AudioMixer.sv`, `LERP.sv`, `PISO.sv`, `RegisterFile.sv`, `RegisterFile_1.sv`, and `RegisterFile_2.sv`. These are intentionally still named like the generated modules so the larger generated integration files can keep building while the internals are retired piece by piece.

The framebuffer helper pass converted `PageFlipper.sv`, `PageFlipper_1.sv`, `RequestQueue.sv`, and `RequestQueue_1.sv` while preserving their generated module ports. `RegisterFile_1.sv` was also adjusted back to explicit registers so Quartus should not spend an M10K RAM block on the tiny sprite/video register files.

An earlier cleanup pass temporarily added a custom TimeQuest report hook at `scripts/timequest_reports.tcl` to write detailed setup, hold, and recovery path reports under `output_files/timing_paths/`. That hook has been removed so the Quartus project follows the normal MiSTer core layout and does not require an extra `scripts/` folder during builds.

The detailed hold report showed the hold miss is not inside the converted helpers. The failing path is from `Main:main|CPU:cpu|fx68k:cpu|excUnit:excUnit|aob[5]` on the 32 MHz clock into `MemSys:memSys|ReadCache:progRomCache|requestReg_addr_index[2]` on the 96 MHz clock. Treat this as a core CPU-to-ROM-cache timing boundary to investigate separately, rather than a reason to revert the page/request helper conversion.

The first safe consolidation pass added `rtl/cave/CaveSyncReadMem.sv` and rewired the small Chisel memory wrapper modules (`cacheEntryMem_*`, `channelStateMem_*`, `ram_32x64`, and `ram_64x64`) as compatibility shells around it. This preserves external module names while removing duplicated generated memory bodies.

The next consolidation pass added `rtl/cave/CaveSyncQueue.sv` and rewired the generated single-clock queue modules (`Queue32_UInt64`, `Queue64_UInt`, and `Queue64_UInt64`) as compatibility shells around it. This keeps the old module names for the larger generated integration files while giving us one hand-maintained queue implementation.

The RAM wrapper pass added `rtl/cave/CaveSinglePortRam.sv` and `rtl/cave/CaveTrueDualPortRam.sv`. The generated `SinglePortRam*` and `TrueDualPortRam*` modules now remain only as compatibility shells over those shared wrappers, which still target the existing Arcadia VHDL RAM implementations.

The dual-clock FIFO pass added `rtl/cave/CaveDualClockFIFO.sv`. The generated `DualClockFIFO*` modules now remain as compatibility shells over that shared wrapper, which still targets the existing Arcadia VHDL `dual_clock_fifo` implementation.

The burst buffer pass rewrote `rtl/cave/BurstBuffer.sv` and `rtl/cave/BurstBuffer_1.sv` as hand-maintained SystemVerilog while preserving their generated module ports. These modules adapt 16-bit download writes to 64-bit DDR bursts and 64-bit download writes back to 16-bit SDRAM bursts.

The burst DMA pass rewrote `rtl/cave/BurstReadDMA.sv`, `rtl/cave/BurstReadDMA_1.sv`, and `rtl/cave/BurstWriteDMA.sv` as hand-maintained SystemVerilog while preserving their generated module ports and existing FIFO wrappers. These modules move data between burst DDR paths and the simpler framebuffer/download write paths.

The burst arbiter pass rewrote `rtl/cave/BurstMemArbiter.sv`, `rtl/cave/BurstMemArbiter_1.sv`, and `rtl/cave/BurstMemArbiter_2.sv` as hand-maintained priority arbiters while preserving their generated module ports. These modules lock a selected requester until the shared memory port reports `burstDone`.

The async memory pass rewrote `rtl/cave/AsyncMemArbiter.sv`, `rtl/cave/AsyncReadMemArbiter.sv`, `rtl/cave/DataFreezer.sv`, `rtl/cave/ReadDataFreezer.sv`, and `rtl/cave/ReadDataFreezer_1.sv` as hand-maintained SystemVerilog while preserving their generated module ports. The arbiters lock read requests until `valid`, while the freezer modules stretch wait/valid/data responses across the CPU/audio clock boundary.

The read cache pass added `rtl/cave/CaveReadCache.sv` as the shared implementation behind `ReadCache.sv`, `ReadCache_1.sv`, and `ReadCache_3.sv`. The old module names remain as compatibility wrappers for the program ROM, sound ROM, and layer tile ROM paths.

After the first shared-cache hardware test, the core did not boot. The fix was to match the original Chisel address decoding for input-word selection: byte addresses must be shifted by the input data width before selecting the cached word. This matters most for the 16-bit program ROM cache.

The sound wrapper pass added `rtl/cave/CaveClockEnable.sv` and `rtl/cave/CaveOKIM6295.sv`. `OKIM6295.sv`, `OKIM6295_1.sv`, and `YM2203.sv` are now hand-maintained wrappers around the external JT sound cores, with the original module ports preserved.

The OKI banking pass rewrote `rtl/cave/NMK112.sv` as hand-maintained SystemVerilog while preserving the generated module ports. The first OKI chip keeps phrase table banking disabled, while the second chip still bank-switches phrase-table addresses below `0x400`.

The current smoke-good soak build is the sprite processor conversion build. Its fresh `output_files/Arcade-Cave.rbf` SHA-256 is `00760f4c57d81a1f13143bc6c021f5562ad82755ef173b0ce84e47528efd2151`.

Build validation rule: when a new build does not byte-match the current smoke-good RBF, inspect the timing/resource reports and take one source-level pass to see whether the changed RTL can be made cleaner or closer to the old synthesis shape before asking for a smoke test. If the RBF byte-matches the smoke-good reference, no smoke test is needed unless there is another concrete concern.

The clock crossing pass rewrote `rtl/cave/Crossing.sv` as hand-maintained SystemVerilog. It still preserves the generated module ports, but now instantiates `CaveDualClockFIFO` directly for the tile-ROM request and response FIFOs instead of going through generated `DualClockFIFO` compatibility wrappers.

The video timing pass added `rtl/cave/CaveVideoTiming.sv` as the shared implementation behind `VideoTiming.sv` and `VideoTiming_1.sv`. The two wrapper modules preserve the generated ports and select the original (`448x272`) or compatibility (`445x262`) timing totals.

The video subsystem pass rewrote `rtl/cave/VideoSys.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original video-register download byte swap, default timing register values, programmed retrace adjustments, CRT offset latching on each timing generator's VSYNC, compatibility-mode latch during shared VBLANK, and registered timing output mux.

The CPU wrapper pass rewrote `rtl/cave/CPU.sv` and `rtl/cave/CPU_1.sv` as hand-maintained SystemVerilog while preserving their generated ports. The external `fx68k` and `T80s` CPU cores are still treated as third-party RTL blocks and were not modified.

The color mixer pass rewrote `rtl/cave/ColorMixer.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original Cave layer priority order and palette RAM addressing rules, but names the fill/sprite/layer selectors so future board-profile work has a clearer place to reason about priority and palette-bank differences.

The layer processor pass added `rtl/cave/CaveLayerProcessor.sv` as the shared hand-maintained tilemap renderer behind `LayerProcessor.sv`, `LayerProcessor_1.sv`, and `LayerProcessor_2.sv`. The wrappers preserve the generated module names and only supply the per-layer horizontal offset. The shared implementation keeps the original line-effect latch, scroll/flip/sprite-offset math, VRAM and line-RAM address generation, tile ROM address generation for 8x8/16x16 and 4bpp/8bpp formats, pixel decode order, and palette pen output gating.

The sprite decoder pass rewrote `rtl/cave/SpriteDecoder.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original ready/valid/toggle sequencing and the 4bpp, 4bpp MSB, and 8bpp nibble mapping, but names the format and pixel decode signals for future sprite hardware work.

The sprite blitter pass rewrote `rtl/cave/SpriteBlitter.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original PISO-fed pixel flow, fixed-point zoom/flip coordinate math, visibility test, and framebuffer address mapping, but names the control and position signals for future sprite hardware work.

The sprite processor pass rewrote `rtl/cave/SpriteProcessor.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original eight-state sprite scheduler, 1024-entry sprite counter, visible-sprite check, tile-ROM burst request threshold, burst-pending latch, tile counter wrap behavior, zoom/non-zoom sprite field decode, and the existing FIFO-to-decoder-to-blitter pipeline.

The GPU pass rewrote `rtl/cave/GPU.sv` as a hand-maintained SystemVerilog integration shell while preserving the generated ports. It keeps the original sprite processor, three layer processors, color mixer, sprite line-buffer read address, RGB555-to-RGB888 expansion, rotate/flip framebuffer address math, and registered system-framebuffer write path.

The GPU conversion build exact-matched the current sprite-processor smoke-good RBF (`00760f4c57d81a1f13143bc6c021f5562ad82755ef173b0ce84e47528efd2151`), so no additional smoke test was needed.

The memory subsystem pass rewrote `rtl/cave/MemSys.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the ROM download path through DDR, the copy DMA into SDRAM, the program/sound/layer ROM caches, the EEPROM write-back cache, DDR and SDRAM arbiter requester priority/order, game-config ROM offset addition, NVRAM arbitration, and the post-copy ready latch.

The memory subsystem conversion build exact-matched the current sprite-processor smoke-good RBF (`00760f4c57d81a1f13143bc6c021f5562ad82755ef173b0ce84e47528efd2151`), so no additional smoke test was needed.

The core top-level pass rewrote `rtl/cave/Cave.sv` as a hand-maintained SystemVerilog integration shell while preserving the generated ports. It keeps the IOCTL ROM/NVRAM/video/DIP dispatch, game-index latch and options fallback, vblank-delayed sprite start pulse, CPU reset gating on memory readiness, main/sound/GPU/framebuffer wiring, layer tile-ROM crossings, program ROM and EEPROM freezers, and the fixed LED/video/SDRAM outputs.

The core top-level conversion build exact-matched the current sprite-processor smoke-good RBF (`00760f4c57d81a1f13143bc6c021f5562ad82755ef173b0ce84e47528efd2151`), so no additional smoke test was needed.

The main board pass converted `rtl/cave/Main.sv` into the hand-maintained Cave HDL list and named the top-level 68k board glue: game selectors, CPU byte address, vblank/pause strobes, Hotdog Storm sprite-swap pulse, and the Guwange/Gaia/Uo Poko input and EEPROM routing hooks. Its large per-game chip-select lattice intentionally remains equation-for-equation close to the legacy Chisel output; extracting that into board-profile decode helpers should be a separate, test-heavy step.

The main board conversion build exact-matched the current sprite-processor smoke-good RBF (`00760f4c57d81a1f13143bc6c021f5562ad82755ef173b0ce84e47528efd2151`), so no additional smoke test was needed.

The repository cleanup pass removed accidental Finder-style `* 2*` duplicate files/directories, merged split legacy Chisel arcadia tests back into `legacy/chisel/arcadia/test/src/`, removed stale `.DS_Store`/temporary files, and left the old `quartus/` project folder retired. The active layout is now root Quartus project files plus `rtl/`, `sys/`, `mra/`, `releases/`, `doc/`, and `legacy/chisel/`.

The sprite framebuffer pass rewrote `rtl/cave/SpriteFrameBuffer.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original line-buffer RAM, hblank-triggered read DMA, swap-triggered clear DMA, write request queue, page flipper, and three-port DDR arbiter wiring, but names the page and DDR address paths.

The system framebuffer pass rewrote `rtl/cave/SystemFrameBuffer.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original HDMI-rotation framebuffer control wiring, page flipper read/write swaps, cross-clock write request queue, and DDR write address offset.

The EEPROM pass rewrote `rtl/cave/EEPROM.sv` as a hand-maintained named-state serial EEPROM controller while preserving the generated ports. It keeps the original NVRAM memory interface, command/address shifting, write-enable latch, read dummy bit, word write, erase, write-all, and erase-all behavior.

The DDR bridge pass rewrote `rtl/cave/DDR.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original idle/read-wait/write-wait states, burst-length latch, burst counter wrap, memory/DDR pass-through signals, and `burstDone` behavior.

The SDRAM pass rewrote `rtl/cave/SDRAM.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original SDRAM init command sequence, mode register value, active/read/write/refresh waits, refresh interval, burst valid/done timing, and registered SDRAM I/O signals.

The ADPCM pass rewrote `rtl/cave/ADPCM.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original YMZ280B step-scale lookup, signed delta lookup, arithmetic shifts, and step/sample clamp limits used by the audio pipeline.

The audio pipeline pass rewrote `rtl/cave/AudioPipeline.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original eight-state YMZ280B sample flow: optional ADPCM fetch on interpolation underflow, decode, interpolation index update, level scaling, left-channel pan scaling, and loop-start sample caching.

The YMZ280B pass rewrote `rtl/cave/YMZ280B.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original CPU address/data register behavior, status read-and-clear behavior, IRQ mask/control registers, eight-channel register decoding, and the existing `ChannelController` interface.

The sound PCB pass rewrote `rtl/cave/Sound.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original sound ROM arbitration, DonPachi NMK112 OKI banking, Hotdog Storm Z80 program/bank/RAM/I/O map, command latch behavior, OKI/YM chip routing, and five-input audio mixer latches.

The channel controller pass rewrote `rtl/cave/ChannelController.sv` as hand-maintained SystemVerilog while preserving the generated ports. It keeps the original YMZ280B eight-channel scheduler, packed channel-state RAM layout, sample/nibble address sequencing, loop/end handling, ROM pending-read latch, and signed 17-bit audio accumulation/clamp behavior.

The write-back cache pass rewrote `rtl/cave/Cache.sv` as hand-maintained SystemVerilog while preserving the generated ports. This is the small two-way EEPROM/NVRAM cache; it keeps the original four-word wrapping fill, dirty-line eviction, LRU bit update, byte swapping, and cache-entry memory wrappers.

External HDL blocks currently kept under `rtl/` include:

- `fx68k/` for the Motorola 68000-compatible CPU.
- `t80/` for the Z80-compatible sound CPU path.
- `jt03/` and `jt6295/` for sound devices.
- `arcadia/` for VHDL memory helpers.
- PLL and reset wrappers at the `rtl/` root.

Next modernization targets:

- Decide whether to replace `sys/` wholesale with the current template framework.
- Continue extracting game-specific configuration and board profile data out of large `rtl/cave/*.sv` integration files into hand-maintained HDL/package data.
- Add a debug grid layer for CPU bus, ROM loader, sound, tile, sprite, and interrupt state.
- Create a clear board-profile structure before adding harder games such as Pretty Soldier Sailor Moon.
