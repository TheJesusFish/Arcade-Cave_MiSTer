module AirGalletMainDecoder(
  input         game_active,
  input  [22:0] cpu_addr,
  input  [2:0]  cpu_fc,
  input         cpu_as,
  input         cpu_rw,
  input         read_strobe,
  input         write_strobe,
  input         prog_rom_valid,
  input         dtack_reg,
  output [23:0] cpu_byte_addr,
  output        prog_rom_select,
  output        extra_rom_select,
  output        work_ram_select,
  output [14:0] work_ram_addr,
  output        main_ram_select,
  output        palette_select,
  output [14:0] palette_ram_addr,
  output        sprite_ram_select,
  output        input0_select,
  output        input1_select,
  output        input0_read,
  output        input1_read,
  output        eeprom_select,
  output        eeprom_write,
  output        layer0_vram8_select,
  output        layer1_vram8_select,
  output        layer2_vram8_select,
  output        layer0_regs_select,
  output        layer1_regs_select,
  output        layer2_regs_select,
  output        sprite_regs_select,
  output        irq_select,
  output        irq_read,
  output [1:0]  irq_word_offset,
  output        sound_select,
  output        sound_flags_read,
  output        sound_read,
  output        sound_write,
  output        sprite_swap_write,
  output        prog_rom_access,
  output        prog_rom_ready,
  output        sync_dtack,
  output        cycle,
  output        known_select,
  output        unmapped_cycle,
  output        prog_rom_read,
  output        work_ram_read,
  output        work_ram_write,
  output        main_ram_read,
  output        main_ram_write,
  output        palette_read,
  output        palette_write,
  output        sprite_ram_read,
  output        sprite_ram_write,
  output        layer0_vram8_read,
  output        layer1_vram8_read,
  output        layer2_vram8_read,
  output        layer0_vram8_write,
  output        layer1_vram8_write,
  output        layer2_vram8_write,
  output        layer0_regs_write,
  output        layer1_regs_write,
  output        layer2_regs_write,
  output        sprite_regs_write,
  output        cpu_space,
  output        data_strobe,
  output        open_bus_select,
  output        dtack
);
  assign cpu_byte_addr = {cpu_addr, 1'b0};

  assign prog_rom_select = cpu_byte_addr < 24'h080000;
  assign extra_rom_select =
    (cpu_byte_addr >= 24'h200000) & (cpu_byte_addr < 24'h400000);
  wire work_ram_0_select =
    (cpu_byte_addr >= 24'h400000) & (cpu_byte_addr < 24'h408000);
  wire work_ram_1_select =
    (cpu_byte_addr >= 24'h40c000) & (cpu_byte_addr < 24'h410000);
  wire work_ram_110_select =
    (cpu_byte_addr >= 24'h110000) & (cpu_byte_addr < 24'h110004);
  wire work_ram_410_select =
    (cpu_byte_addr >= 24'h410000) & (cpu_byte_addr < 24'h410004);
  wire work_ram_510_select =
    (cpu_byte_addr >= 24'h510000) & (cpu_byte_addr < 24'h510004);
  wire work_ram_908_select =
    (cpu_byte_addr >= 24'h908000) & (cpu_byte_addr < 24'h908004);

  assign work_ram_select =
    work_ram_0_select | work_ram_1_select | work_ram_110_select |
    work_ram_410_select | work_ram_510_select | work_ram_908_select;
  assign work_ram_addr =
    work_ram_0_select   ? {1'b0, cpu_addr[13:0]} :
    work_ram_1_select   ? {2'b10, cpu_addr[12:0]} :
    work_ram_110_select ? (15'h6000 + {14'h0, cpu_addr[0]}) :
    work_ram_410_select ? (15'h6002 + {14'h0, cpu_addr[0]}) :
    work_ram_510_select ? (15'h6004 + {14'h0, cpu_addr[0]}) :
    work_ram_908_select ? (15'h6006 + {14'h0, cpu_addr[0]}) :
    15'h0000;
  assign main_ram_select =
    (cpu_byte_addr >= 24'h100000) & (cpu_byte_addr < 24'h110000);
  assign palette_select =
    (cpu_byte_addr >= 24'h408000) & (cpu_byte_addr < 24'h40c000);
  assign palette_ram_addr = cpu_addr[14:0] - 15'h4000;
  assign sprite_ram_select =
    (cpu_byte_addr >= 24'h500000) & (cpu_byte_addr < 24'h510000);
  assign input0_select =
    (cpu_byte_addr >= 24'h600000) & (cpu_byte_addr < 24'h600002);
  assign input1_select =
    (cpu_byte_addr >= 24'h600002) & (cpu_byte_addr < 24'h600004);
  assign input0_read = input0_select & read_strobe;
  assign input1_read = input1_select & read_strobe;
  assign eeprom_select = cpu_byte_addr == 24'h700000;
  assign eeprom_write = eeprom_select & write_strobe;
  assign layer0_vram8_select =
    (cpu_byte_addr >= 24'h800000) & (cpu_byte_addr < 24'h808000);
  assign layer1_vram8_select =
    (cpu_byte_addr >= 24'h880000) & (cpu_byte_addr < 24'h888000);
  assign layer2_vram8_select =
    (cpu_byte_addr >= 24'h900000) & (cpu_byte_addr < 24'h908000);
  assign layer0_regs_select =
    (cpu_byte_addr >= 24'ha00000) & (cpu_byte_addr < 24'ha00006);
  assign layer1_regs_select =
    (cpu_byte_addr >= 24'ha80000) & (cpu_byte_addr < 24'ha80006);
  assign layer2_regs_select =
    (cpu_byte_addr >= 24'hb00000) & (cpu_byte_addr < 24'hb00006);
  assign sprite_regs_select =
    (cpu_byte_addr >= 24'hb80000) & (cpu_byte_addr < 24'hb80080);
  assign irq_select =
    (cpu_byte_addr >= 24'hb80000) & (cpu_byte_addr < 24'hb80008);
  assign irq_read = irq_select & read_strobe;
  assign irq_word_offset = cpu_addr[1:0];
  assign sound_flags_read =
    (cpu_byte_addr >= 24'hb8006c) & (cpu_byte_addr < 24'hb8006e) &
    read_strobe;
  assign sound_select =
    ((cpu_byte_addr >= 24'hb8006c) & (cpu_byte_addr < 24'hb80070));
  assign sound_read =
    (cpu_byte_addr >= 24'hb8006e) & (cpu_byte_addr < 24'hb80070) &
    read_strobe;
  assign sound_write =
    (cpu_byte_addr >= 24'hb8006e) & (cpu_byte_addr < 24'hb80070) &
    write_strobe;
  assign sprite_swap_write = (cpu_byte_addr == 24'hb80008) & write_strobe;

  assign prog_rom_access = prog_rom_select;
  assign prog_rom_ready = prog_rom_access & cpu_rw & prog_rom_valid;
  assign sync_dtack =
    main_ram_select | work_ram_select | palette_select | sprite_ram_select |
    layer0_vram8_select | layer1_vram8_select | layer2_vram8_select |
    layer0_regs_select | layer1_regs_select | layer2_regs_select |
    sprite_regs_select | extra_rom_select | input0_read | input1_read |
    eeprom_write;
  assign cycle = game_active & cpu_as;
  assign known_select =
    prog_rom_access | extra_rom_select | main_ram_select | work_ram_select |
    palette_select | sprite_ram_select | input0_select | input1_select |
    eeprom_select | layer0_vram8_select | layer1_vram8_select |
    layer2_vram8_select | layer0_regs_select | layer1_regs_select |
    layer2_regs_select | sprite_regs_select | sound_select;
  assign unmapped_cycle = cycle & ~known_select;

  assign prog_rom_read = prog_rom_select & read_strobe;
  assign work_ram_read = work_ram_select & read_strobe;
  assign work_ram_write = work_ram_select & write_strobe;
  assign main_ram_read = main_ram_select & read_strobe;
  assign main_ram_write = main_ram_select & write_strobe;
  assign palette_read = palette_select & read_strobe;
  assign palette_write = palette_select & write_strobe;
  assign sprite_ram_read = sprite_ram_select & read_strobe;
  assign sprite_ram_write = sprite_ram_select & write_strobe;
  assign layer0_vram8_read = layer0_vram8_select & read_strobe;
  assign layer1_vram8_read = layer1_vram8_select & read_strobe;
  assign layer2_vram8_read = layer2_vram8_select & read_strobe;
  assign layer0_vram8_write = layer0_vram8_select & write_strobe;
  assign layer1_vram8_write = layer1_vram8_select & write_strobe;
  assign layer2_vram8_write = layer2_vram8_select & write_strobe;
  assign layer0_regs_write = layer0_regs_select & write_strobe;
  assign layer1_regs_write = layer1_regs_select & write_strobe;
  assign layer2_regs_write = layer2_regs_select & write_strobe;
  assign sprite_regs_write = sprite_regs_select & write_strobe;

  assign cpu_space = &cpu_fc;
  assign data_strobe = read_strobe | write_strobe;
  assign open_bus_select = unmapped_cycle & ~cpu_space & data_strobe;
  assign dtack = cpu_as & (prog_rom_ready | sync_dtack | sound_select | irq_select | open_bus_select | dtack_reg);
endmodule
