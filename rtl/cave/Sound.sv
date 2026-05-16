// Sound PCB integration: sound CPU, sample chips, banking, ROM arbitration, and mixing.
module Sound(
  input         clock,
  input         reset,
  input         io_ctrl_oki_0_wr,
  input  [15:0] io_ctrl_oki_0_din,
  output [15:0] io_ctrl_oki_0_dout,
  input         io_ctrl_oki_1_wr,
  input  [15:0] io_ctrl_oki_1_din,
  output [15:0] io_ctrl_oki_1_dout,
  input         io_ctrl_nmk_wr,
  input  [22:0] io_ctrl_nmk_addr,
  input  [15:0] io_ctrl_nmk_din,
  input         io_ctrl_ymz_rd,
  input         io_ctrl_ymz_wr,
  input  [22:0] io_ctrl_ymz_addr,
  input  [15:0] io_ctrl_ymz_din,
  output [15:0] io_ctrl_ymz_dout,
  input         io_ctrl_req,
  input  [15:0] io_ctrl_data,
  output        io_ctrl_irq,
  input  [3:0]  io_gameIndex,
  input  [1:0]  io_gameConfig_sound_0_device,
  output        io_rom_0_rd,
  output [24:0] io_rom_0_addr,
  input  [7:0]  io_rom_0_dout,
  input         io_rom_0_wait_n,
  input         io_rom_0_valid,
  output [24:0] io_rom_1_addr,
  input  [7:0]  io_rom_1_dout,
  input         io_rom_1_valid,
  output [15:0] io_audio
);
  localparam [3:0] GAME_DONPACHI = 4'h2;
  localparam [3:0] GAME_HOTDOGST = 4'h7;

  localparam [1:0] SOUND_DEVICE_YMZ280B  = 2'h1;
  localparam [1:0] SOUND_DEVICE_OKIM6259 = 2'h2;
  localparam [1:0] SOUND_DEVICE_Z80      = 2'h3;

  wire        hotdogZ80 = io_gameIndex == GAME_HOTDOGST;
  wire        donpachi = io_gameIndex == GAME_DONPACHI;
  wire        soundDeviceIsOki = io_gameConfig_sound_0_device == SOUND_DEVICE_OKIM6259;
  wire        soundDeviceIsYmz = io_gameConfig_sound_0_device == SOUND_DEVICE_YMZ280B;
  wire        soundDeviceIsZ80 = io_gameConfig_sound_0_device == SOUND_DEVICE_Z80;

  reg         reqReg;
  reg  [15:0] dataReg;
  reg  [3:0]  z80BankReg;
  reg  [3:0]  okiBankHiReg;
  reg  [3:0]  okiBankLoReg;
  reg  [15:0] ymzAudioReg;
  reg  [15:0] ym2203PsgAudioReg;
  reg  [15:0] ym2203FmAudioReg;
  reg  [13:0] oki0AudioReg;
  reg  [13:0] oki1AudioReg;

  wire [15:0] cpuAddr;
  wire [7:0]  cpuDout;
  wire        cpuRd;
  wire        cpuWr;
  wire        cpuRfsh;
  wire        cpuMreq;
  wire        cpuIorq;
  wire        cpuInt;

  wire        z80ProgRomSelect = cpuAddr < 16'h4000;
  wire        z80BankRomSelect = (|cpuAddr[15:14]) & ~cpuAddr[15];
  wire        z80RamSelect = cpuAddr > 16'hDFFF;
  wire [15:0] cpuIoAddr = {8'h00, cpuAddr[7:0]};
  wire        latchLowRead = (cpuIoAddr > 16'h002F) & (cpuIoAddr < 16'h0031) & cpuIorq & cpuRd;
  wire        latchHighRead = (|cpuAddr[7:6]) & (cpuIoAddr < 16'h0041) & cpuIorq & cpuRd;
  wire        ym2203Access = (cpuIoAddr > 16'h004F) & (cpuIoAddr < 16'h0052) & cpuIorq;
  wire        oki1Access = (cpuIoAddr > 16'h005F) & (cpuIoAddr < 16'h0061) & cpuIorq;
  wire        okiBankWrite = hotdogZ80 & (cpuIoAddr > 16'h006F) & (cpuIoAddr < 16'h0071) & cpuIorq & cpuWr;

  wire [7:0]  soundRamDout;
  wire        soundRamRd = hotdogZ80 & z80RamSelect & ~cpuRfsh;
  wire        soundRamWr = hotdogZ80 & z80RamSelect & cpuMreq & cpuWr;

  wire [7:0]  progRomDout;
  wire [7:0]  bankRomDout;
  wire [7:0]  romOrBankDout = z80BankRomSelect & cpuMreq & cpuRd ? bankRomDout : progRomDout;

  wire [7:0]  oki0CpuDout;
  wire [17:0] oki0RomAddr;
  wire [7:0]  oki0RomDout;
  wire        oki0RomValid;
  wire        oki0AudioValid;
  wire [13:0] oki0Audio;

  wire [7:0]  oki1CpuDout;
  wire [17:0] oki1RomAddr;
  wire        oki1AudioValid;
  wire [13:0] oki1Audio;
  wire        oki1CpuWr = hotdogZ80 ? oki1Access & cpuWr : io_ctrl_oki_1_wr;
  wire [7:0]  oki1CpuDin = hotdogZ80 ? cpuDout : io_ctrl_oki_1_din[7:0];

  wire [7:0]  ym2203CpuDout;
  wire        ym2203AudioValid;
  wire [15:0] ym2203PsgAudio;
  wire [15:0] ym2203FmAudio;

  wire [7:0]  cpuDin =
    oki1Access & cpuRd    ? oki1CpuDout :
    ym2203Access & cpuRd  ? ym2203CpuDout :
    latchHighRead         ? dataReg[15:8] :
    latchLowRead          ? dataReg[7:0] :
    z80RamSelect & cpuMreq & cpuRd ? soundRamDout :
    romOrBankDout;

  wire [7:0]  ymzCpuDout;
  wire        ymzRomRd;
  wire [23:0] ymzRomAddr;
  wire [7:0]  ymzRomDout;
  wire        ymzRomWaitN;
  wire        ymzRomValid;
  wire        ymzAudioValid;
  wire [15:0] ymzAudio;

  wire [24:0] nmkOki0AddrOut;
  wire [24:0] nmkOki1AddrOut;
  wire [3:0]  oki0Bank = oki0RomAddr[17] ? okiBankHiReg : okiBankLoReg;
  wire [3:0]  oki1Bank = oki1RomAddr[17] ? okiBankHiReg : okiBankLoReg;
  wire [24:0] oki0MappedAddr = donpachi ? nmkOki0AddrOut : {4'h0, oki0Bank, oki0RomAddr[16:0]};
  wire [24:0] oki1MappedAddr = donpachi ? nmkOki1AddrOut : {4'h0, oki1Bank, oki1RomAddr[16:0]};

  always @(posedge clock) begin
    if (reset) begin
      reqReg <= 1'b0;
      z80BankReg <= 4'h0;
      okiBankHiReg <= 4'h0;
      okiBankLoReg <= 4'h0;
    end
    else begin
      reqReg <= ~(hotdogZ80 & (latchHighRead | latchLowRead)) & (io_ctrl_req | reqReg);

      if (hotdogZ80 & (cpuAddr[7:0] == 8'h00) & cpuIorq & cpuWr)
        z80BankReg <= cpuDout[3:0];

      if (okiBankWrite) begin
        okiBankHiReg <= {2'b00, cpuDout[5:4]};
        okiBankLoReg <= {2'b00, cpuDout[1:0]};
      end
    end

    if (io_ctrl_req)
      dataReg <= io_ctrl_data;

    if (ymzAudioValid)
      ymzAudioReg <= ymzAudio;

    if (ym2203AudioValid) begin
      ym2203PsgAudioReg <= ym2203PsgAudio;
      ym2203FmAudioReg <= ym2203FmAudio;
    end

    if (oki0AudioValid)
      oki0AudioReg <= oki0Audio;

    if (oki1AudioValid)
      oki1AudioReg <= oki1Audio;
  end

  CPU_1 cpu (
    .clock   (clock),
    .reset   (reset),
    .io_addr (cpuAddr),
    .io_din  (cpuDin),
    .io_dout (cpuDout),
    .io_rd   (cpuRd),
    .io_wr   (cpuWr),
    .io_rfsh (cpuRfsh),
    .io_mreq (cpuMreq),
    .io_iorq (cpuIorq),
    .io_int  (cpuInt),
    .io_nmi  (reqReg)
  );

  SinglePortRam_1 soundRam (
    .clock   (clock),
    .io_rd   (soundRamRd),
    .io_wr   (soundRamWr),
    .io_addr (cpuAddr[12:0]),
    .io_din  (cpuDout),
    .io_dout (soundRamDout)
  );

  NMK112 nmk (
    .clock         (clock),
    .io_cpu_wr     (io_ctrl_nmk_wr),
    .io_cpu_addr   (io_ctrl_nmk_addr),
    .io_cpu_din    (io_ctrl_nmk_din),
    .io_addr_0_in  ({7'h00, oki0RomAddr}),
    .io_addr_0_out (nmkOki0AddrOut),
    .io_addr_1_in  ({7'h00, oki1RomAddr}),
    .io_addr_1_out (nmkOki1AddrOut)
  );

  OKIM6295 oki_0 (
    .clock          (clock),
    .reset          (reset),
    .io_cpu_wr      (io_ctrl_oki_0_wr),
    .io_cpu_din     (io_ctrl_oki_0_din[7:0]),
    .io_cpu_dout    (oki0CpuDout),
    .io_rom_addr    (oki0RomAddr),
    .io_rom_dout    (oki0RomDout),
    .io_rom_valid   (oki0RomValid),
    .io_audio_valid (oki0AudioValid),
    .io_audio_bits  (oki0Audio)
  );

  OKIM6295_1 oki_1 (
    .clock          (clock),
    .reset          (reset),
    .io_cpu_wr      (oki1CpuWr),
    .io_cpu_din     (oki1CpuDin),
    .io_cpu_dout    (oki1CpuDout),
    .io_rom_addr    (oki1RomAddr),
    .io_rom_dout    (io_rom_1_dout),
    .io_rom_valid   (io_rom_1_valid),
    .io_audio_valid (oki1AudioValid),
    .io_audio_bits  (oki1Audio)
  );

  YMZ280B ymz280b (
    .clock              (clock),
    .reset              (reset),
    .io_cpu_rd          (io_ctrl_ymz_rd),
    .io_cpu_wr          (io_ctrl_ymz_wr),
    .io_cpu_addr        (io_ctrl_ymz_addr[0]),
    .io_cpu_din         (io_ctrl_ymz_din[7:0]),
    .io_cpu_dout        (ymzCpuDout),
    .io_rom_rd          (ymzRomRd),
    .io_rom_addr        (ymzRomAddr),
    .io_rom_dout        (ymzRomDout),
    .io_rom_wait_n      (ymzRomWaitN),
    .io_rom_valid       (ymzRomValid),
    .io_audio_valid     (ymzAudioValid),
    .io_audio_bits_left (ymzAudio),
    .io_irq             (io_ctrl_irq)
  );

  YM2203 ym2203 (
    .clock             (clock),
    .reset             (reset),
    .io_cpu_wr         (hotdogZ80 & ym2203Access & cpuWr),
    .io_cpu_addr       (cpuAddr[0]),
    .io_cpu_din        (cpuDout),
    .io_cpu_dout       (ym2203CpuDout),
    .io_irq            (cpuInt),
    .io_audio_valid    (ym2203AudioValid),
    .io_audio_bits_psg (ym2203PsgAudio),
    .io_audio_bits_fm  (ym2203FmAudio)
  );

  AsyncReadMemArbiter arbiter (
    .clock          (clock),
    .reset          (reset),
    .io_in_0_rd     (soundDeviceIsOki),
    .io_in_0_addr   (oki0MappedAddr),
    .io_in_0_dout   (oki0RomDout),
    .io_in_0_valid  (oki0RomValid),
    .io_in_1_rd     (soundDeviceIsYmz & ymzRomRd),
    .io_in_1_addr   ({1'b0, ymzRomAddr}),
    .io_in_1_dout   (ymzRomDout),
    .io_in_1_wait_n (ymzRomWaitN),
    .io_in_1_valid  (ymzRomValid),
    .io_in_2_rd     (soundDeviceIsZ80 & hotdogZ80 & z80ProgRomSelect & ~cpuRfsh),
    .io_in_2_addr   ({9'h000, cpuAddr}),
    .io_in_2_dout   (progRomDout),
    .io_in_3_rd     (soundDeviceIsZ80 & hotdogZ80 & z80BankRomSelect & ~cpuRfsh),
    .io_in_3_addr   ({7'h00, z80BankReg, cpuAddr[13:0]}),
    .io_in_3_dout   (bankRomDout),
    .io_out_rd      (io_rom_0_rd),
    .io_out_addr    (io_rom_0_addr),
    .io_out_dout    (io_rom_0_dout),
    .io_out_wait_n  (io_rom_0_wait_n),
    .io_out_valid   (io_rom_0_valid)
  );

  AudioMixer io_audio_mixer (
    .clock   (clock),
    .io_in_4 (oki1AudioReg),
    .io_in_3 (oki0AudioReg),
    .io_in_2 (ym2203FmAudioReg),
    .io_in_1 (ym2203PsgAudioReg),
    .io_in_0 (ymzAudioReg),
    .io_out  (io_audio)
  );

  assign io_ctrl_oki_0_dout = {8'h00, oki0CpuDout};
  assign io_ctrl_oki_1_dout = {8'h00, oki1CpuDout};
  assign io_ctrl_ymz_dout = {8'h00, ymzCpuDout};
  assign io_rom_1_addr = oki1MappedAddr;
endmodule
