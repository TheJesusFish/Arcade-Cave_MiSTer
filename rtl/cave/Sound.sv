// This file is a Codex-assisted rewrite based on the original work of
// Josh Bassett (nullobject).

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
  input         io_ctrl_reply_rd,
  output [15:0] io_ctrl_reply,
  output        io_ctrl_irq,
  input  [3:0]  io_gameIndex,
  input  [1:0]  io_gameConfig_sound_0_device,
  output        io_rom_0_rd,
  output [24:0] io_rom_0_addr,
  input  [7:0]  io_rom_0_dout,
  input         io_rom_0_wait_n,
  input         io_rom_0_valid,
  output        io_rom_1_rd,
  output [24:0] io_rom_1_addr,
  input  [7:0]  io_rom_1_dout,
  input         io_rom_1_valid,
  output        io_rom_2_rd,
  output [24:0] io_rom_2_addr,
  input  [7:0]  io_rom_2_dout,
  input         io_rom_2_valid,
  output [63:0] io_debug,
  output [15:0] io_audio
);
  wire        hotdogZ80;
  wire        mazingerZ80;
  wire        airgalletZ80;
  wire        sailormoonZ80;
  wire        airFamilyZ80Sound;
  wire        z80Game;
  wire        donpachi;
  wire        soundDeviceIsOki;
  wire        soundDeviceIsYmz;
  wire        soundDeviceIsZ80;

  CaveBoardProfile boardProfile(
    .game_index                  (io_gameIndex),
    .sound_device                (io_gameConfig_sound_0_device),
    .game_is_dfeveron            (),
    .game_is_dodonpachi          (),
    .game_is_donpachi            (donpachi),
    .game_is_esprade             (),
    .game_is_uopoko              (),
    .game_is_guwange             (),
    .game_is_gaia                (),
    .game_is_hotdogstorm         (hotdogZ80),
    .game_is_mazinger            (mazingerZ80),
    .game_is_airgallet           (airgalletZ80),
    .game_is_sailormoon          (sailormoonZ80),
    .board_uses_z80_sound        (z80Game),
    .board_is_vertical_clockwise (),
    .sound_is_ymz280b            (soundDeviceIsYmz),
    .sound_is_oki                (soundDeviceIsOki),
    .sound_is_z80                (soundDeviceIsZ80)
  );

  assign airFamilyZ80Sound = airgalletZ80 | sailormoonZ80;

  reg         reqReg;
  reg  [15:0] dataReg;
  reg  [4:0]  z80BankReg;
  reg  [3:0]  oki0BankHiReg;
  reg  [3:0]  oki0BankLoReg;
  reg  [3:0]  oki1BankHiReg;
  reg  [3:0]  oki1BankLoReg;
  reg  [15:0] ymzAudioReg;
  reg  [15:0] ym2203PsgAudioReg;
  reg  [15:0] ym2203FmAudioReg;
  reg  [15:0] ym2151AudioReg;
  reg  [13:0] oki0AudioReg;
  reg  [13:0] oki1AudioReg;
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
  reg  [7:0]  debugLastSoundCommand;
  reg  [7:0]  debugLastReply;
  reg  [7:0]  debugLastLatchRead;
  reg  [7:0]  debugLastOkiBank;
  reg  [7:0]  debugLastOkiPhrase;
  reg  [7:0]  debugLastOkiStart;
  reg  [7:0]  debugLastYmAddr;
  reg  [7:0]  debugLastYmData;
  reg  [7:0]  debugLastIoAddr;
  reg  [7:0]  debugLastIoData;
  reg  [7:0]  debugLastOkiRomAddr;
  reg  [7:0]  debugLastOkiRomData;
  reg  [7:0]  debugLastZ80RomAddrHi;
  reg  [7:0]  debugLastZ80RomAddrLo;
  reg  [7:0]  debugLastZ80RomData;
  reg  [7:0]  debugFlags;
  reg         debugOkiPhrasePending;
`endif
  reg         z80IoWrD;
  reg  [7:0]  z80IoWrAddrD;
  reg  [7:0]  z80IoWrDataD;
  reg  [7:0]  replyFifo [0:31];
  reg  [4:0]  replyReadPtr;
  reg  [4:0]  replyWritePtr;
  reg  [5:0]  replyCount;

  wire [15:0] cpuAddr;
  wire [7:0]  cpuDout;
  wire        cpuRd;
  wire        cpuWr;
  wire        cpuRfsh;
  wire        cpuMreq;
  wire        cpuIorq;
  wire        cpuInt;
  wire        ym2203Irq;
  wire        ym2151Irq;

  wire        z80ProgRomSelect = cpuAddr < 16'h4000;
  wire        z80BankRomSelect = (|cpuAddr[15:14]) & ~cpuAddr[15];
  wire        z80RamSelect =
    hotdogZ80 ? cpuAddr > 16'hDFFF :
    mazingerZ80 ? ((cpuAddr > 16'hBFFF) & (cpuAddr < 16'hC800)) | (cpuAddr > 16'hF7FF) :
    airFamilyZ80Sound ? cpuAddr >= 16'hC000 :
                  1'b0;
  wire [15:0] cpuIoAddr = {8'h00, cpuAddr[7:0]};
  wire        z80IoWr = z80Game & cpuIorq & cpuWr;
  wire        z80IoWrChanged =
    z80IoWr & ((cpuIoAddr[7:0] != z80IoWrAddrD) | (cpuDout != z80IoWrDataD));
  wire        z80IoWrPulse = z80IoWr & (~z80IoWrD | (airFamilyZ80Sound & z80IoWrChanged));
  wire        latchLowRead = z80Game & (cpuIoAddr == 16'h0030) & cpuIorq & cpuRd;
  wire        latchHighRead = (hotdogZ80 | airFamilyZ80Sound) & (cpuIoAddr == 16'h0040) & cpuIorq & cpuRd;
  wire        soundFlagsRead = airFamilyZ80Sound & (cpuIoAddr == 16'h0020) & cpuIorq & cpuRd;
  wire        airYm2151Access = airFamilyZ80Sound & (cpuIoAddr > 16'h004F) & (cpuIoAddr < 16'h0052) & cpuIorq;
  wire        airYm2151Write = airYm2151Access & z80IoWrPulse;
  wire        airYm2151Read = airYm2151Access & cpuRd;
  wire        ym2203ClassicWrite =
    ~airFamilyZ80Sound & z80Game &
    (cpuIoAddr > 16'h004F) & (cpuIoAddr < 16'h0052) & z80IoWrPulse;
  wire        ym2203ClassicRead =
    ((hotdogZ80 & (cpuIoAddr > 16'h004F) & (cpuIoAddr < 16'h0052)) |
     (mazingerZ80 & (cpuIoAddr > 16'h0051) & (cpuIoAddr < 16'h0054))) & cpuIorq & cpuRd;
  wire        ym2203Write = ym2203ClassicWrite;
  wire        ym2203Read = ym2203ClassicRead;
  wire        oki0Access =
    (airFamilyZ80Sound & (cpuIoAddr == 16'h0060)) & cpuIorq;
  wire        oki1Access =
    ((hotdogZ80 & (cpuIoAddr == 16'h0060)) |
     (airFamilyZ80Sound & (cpuIoAddr == 16'h0080)) |
     (mazingerZ80 & (cpuIoAddr == 16'h0070))) & cpuIorq;
  wire        airgalletOki0BankWrite = airFamilyZ80Sound & (cpuIoAddr == 16'h0070) & z80IoWrPulse;
  wire        airgalletOki1BankWrite = airFamilyZ80Sound & (cpuIoAddr == 16'h00C0) & z80IoWrPulse;
  wire        hotdogOkiBankWrite = hotdogZ80 & (cpuIoAddr == 16'h0070) & z80IoWrPulse;
  wire        mazingerOkiBankWrite = mazingerZ80 & (cpuIoAddr == 16'h0074) & z80IoWrPulse;
  wire        oki0BankWrite = airgalletOki0BankWrite;
  wire        oki1BankWrite = airgalletOki1BankWrite | hotdogOkiBankWrite | mazingerOkiBankWrite;
  wire        okiBankWrite = oki0BankWrite | oki1BankWrite;
  wire        soundReplyWrite = (mazingerZ80 | airFamilyZ80Sound) & (cpuIoAddr == 16'h0010) & z80IoWrPulse;
  wire        replyPop = io_ctrl_reply_rd & (replyCount != 6'd0);
  wire        replyPush = soundReplyWrite & ((replyCount != 6'd32) | replyPop);

  wire [7:0]  soundRamDout;
  wire        soundRamRd = z80Game & z80RamSelect & ~cpuRfsh;
  wire        soundRamWr = z80Game & z80RamSelect & cpuMreq & cpuWr;

  wire [7:0]  progRomDout;
  wire        progRomValid;
  wire [7:0]  bankRomDout;
  wire        bankRomValid;
  wire        z80RomRead = z80Game & cpuMreq & cpuRd & ~cpuRfsh & (z80ProgRomSelect | z80BankRomSelect);
  wire        z80ProgRomArbiterRead =
    soundDeviceIsZ80 & z80Game & z80ProgRomSelect & ~cpuRfsh &
    (airFamilyZ80Sound ? (cpuMreq & cpuRd) : 1'b1);
  wire        z80BankRomArbiterRead =
    soundDeviceIsZ80 & z80Game & z80BankRomSelect & ~cpuRfsh &
    (airFamilyZ80Sound ? (cpuMreq & cpuRd) : 1'b1);
  wire        z80RomValid = z80BankRomSelect ? bankRomValid : progRomValid;
  wire        z80RomNeedsWait = airFamilyZ80Sound;
  wire        z80WaitN = ~(z80RomNeedsWait & z80RomRead) | z80RomValid;
  wire [7:0]  romOrBankDout = z80BankRomSelect & cpuMreq & cpuRd ? bankRomDout : progRomDout;

  wire [7:0]  oki0CpuDout;
  wire        oki0RomRead;
  wire [17:0] oki0RomAddr;
  wire [7:0]  oki0RomDout;
  wire        oki0RomValid;
  wire        oki0AudioValid;
  wire [13:0] oki0Audio;
  wire        z80Oki0CpuWr = oki0Access & z80IoWrPulse;
  wire        oki0CpuWrRaw =
    airFamilyZ80Sound ? z80Oki0CpuWr : io_ctrl_oki_0_wr;
  wire [7:0]  oki0CpuDinRaw =
    airFamilyZ80Sound ? cpuDout : io_ctrl_oki_0_din[7:0];
  wire        oki0CpuWr = oki0CpuWrRaw;
  wire [7:0]  oki0CpuDin = oki0CpuDinRaw;
  wire [16:0] oki0CenStep = airFamilyZ80Sound ? 17'h10E5 : 17'h0873;

  wire [7:0]  oki1CpuDout;
  wire        oki1RomRead;
  wire [17:0] oki1RomAddr;
  wire        oki1AudioValid;
  wire [13:0] oki1Audio;
  wire        z80Oki1CpuWr = oki1Access & z80IoWrPulse;
  wire        oki1CpuWrRaw = z80Game ? z80Oki1CpuWr : io_ctrl_oki_1_wr;
  wire [7:0]  oki1CpuDinRaw = z80Game ? cpuDout : io_ctrl_oki_1_din[7:0];
  wire        oki1CpuWr = oki1CpuWrRaw;
  wire [7:0]  oki1CpuDin = oki1CpuDinRaw;
  wire [16:0] oki1CenStep = mazingerZ80 ? 17'h0873 : 17'h10E5;
  wire [7:0]  ym2203CpuDout;
  wire        ym2203AudioValid;
  wire [15:0] ym2203PsgAudio;
  wire [15:0] ym2203FmAudio;
  wire [7:0]  ym2151CpuDout;
  wire        ym2151AudioValid;
  wire [15:0] ym2151Audio;
  wire [7:0]  cpuDin =
    oki0Access & cpuRd    ? oki0CpuDout :
    oki1Access & cpuRd    ? oki1CpuDout :
    airYm2151Read         ? ym2151CpuDout :
    ym2203Read            ? ym2203CpuDout :
    soundFlagsRead        ? 8'h00 :
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
  wire [3:0]  oki0Bank = oki0RomAddr[17] ? oki0BankHiReg : oki0BankLoReg;
  wire [3:0]  oki1Bank = oki1RomAddr[17] ? oki1BankHiReg : oki1BankLoReg;
  wire [24:0] defaultOki0MappedAddr = {4'h0, oki0Bank, oki0RomAddr[16:0]};
  wire [24:0] airOki0MappedAddr = defaultOki0MappedAddr;
  wire [24:0] airOki1MappedAddr = {4'h0, oki1Bank, oki1RomAddr[16:0]};
  wire [24:0] oki0MappedAddr = donpachi ? nmkOki0AddrOut : defaultOki0MappedAddr;
  wire [24:0] oki1MappedAddr = donpachi ? nmkOki1AddrOut : {4'h0, oki1Bank, oki1RomAddr[16:0]};
  wire [7:0]  oki0RomData = airFamilyZ80Sound ? io_rom_1_dout : oki0RomDout;
  wire        oki0RomDataValid = airFamilyZ80Sound ? io_rom_1_valid : oki0RomValid;
  wire [7:0]  oki1RomData = airFamilyZ80Sound ? io_rom_2_dout : io_rom_1_dout;
  wire        oki1RomDataValid = airFamilyZ80Sound ? io_rom_2_valid : io_rom_1_valid;
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
  wire        debugOki1RomDataValid = mazingerZ80 ? io_rom_1_valid : oki1RomDataValid;
`endif

  always @(posedge clock) begin
    if (reset) begin
      reqReg <= 1'b0;
      z80BankReg <= 5'h0;
      oki0BankHiReg <= 4'h0;
      oki0BankLoReg <= 4'h0;
      oki1BankHiReg <= 4'h0;
      oki1BankLoReg <= 4'h0;
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
      debugLastSoundCommand <= 8'h00;
      debugLastReply <= 8'h00;
      debugLastLatchRead <= 8'h00;
      debugLastOkiBank <= 8'h00;
      debugLastOkiPhrase <= 8'h00;
      debugLastOkiStart <= 8'h00;
      debugLastYmAddr <= 8'h00;
      debugLastYmData <= 8'h00;
      debugLastIoAddr <= 8'h00;
      debugLastIoData <= 8'h00;
      debugLastOkiRomAddr <= 8'h00;
      debugLastOkiRomData <= 8'h00;
      debugLastZ80RomAddrHi <= 8'h00;
      debugLastZ80RomAddrLo <= 8'h00;
      debugLastZ80RomData <= 8'h00;
      debugFlags <= 8'h00;
      debugOkiPhrasePending <= 1'b0;
`endif
      z80IoWrD <= 1'b0;
      z80IoWrAddrD <= 8'h00;
      z80IoWrDataD <= 8'h00;
      replyReadPtr <= 5'd0;
      replyWritePtr <= 5'd0;
      replyCount <= 6'd0;
    end
    else begin
      z80IoWrD <= z80IoWr;
      if (z80IoWr) begin
        z80IoWrAddrD <= cpuIoAddr[7:0];
        z80IoWrDataD <= cpuDout;
      end

      reqReg <= ~(z80Game & (latchHighRead | latchLowRead)) & (io_ctrl_req | reqReg);
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
      debugFlags <= debugFlags | (mazingerZ80 ? {
        oki1AudioValid,
        |oki1AudioReg,
        oki1RomDataValid,
        oki1RomRead,
        z80Oki1CpuWr,
        oki1CpuWr,
        oki1Access & cpuRd,
        ym2203Read
      } : {
        debugOki1RomDataValid,
        oki1RomRead,
        z80Oki1CpuWr,
        ym2203Write,
        soundReplyWrite,
        latchHighRead,
        latchLowRead,
        io_ctrl_req
      });

      if (io_ctrl_req)
        debugLastSoundCommand <= io_ctrl_data[7:0];

      if (z80IoWrPulse & (cpuIoAddr[7:0] != 8'h10) & (~mazingerZ80 | ym2203Write | z80Oki1CpuWr | oki1BankWrite)) begin
        debugLastIoAddr <= cpuIoAddr[7:0];
        debugLastIoData <= cpuDout;
      end

      if (latchLowRead)
        debugLastLatchRead <= dataReg[7:0];
      else if (latchHighRead)
        debugLastLatchRead <= dataReg[15:8];

      if (oki1BankWrite)
        debugLastOkiBank <= cpuDout;

      if (z80Oki1CpuWr) begin
        if (cpuDout[7]) begin
          debugLastOkiPhrase <= cpuDout;
          debugOkiPhrasePending <= 1'b1;
        end
        else if (debugOkiPhrasePending) begin
          debugLastOkiStart <= cpuDout;
          debugOkiPhrasePending <= 1'b0;
        end
        else begin
          debugLastOkiStart <= cpuDout;
        end
      end

      if (ym2203Write) begin
        if (cpuIoAddr[0])
          debugLastYmData <= cpuDout;
        else
          debugLastYmAddr <= cpuDout;
      end

      if (mazingerZ80 & oki1RomRead)
        debugLastOkiRomAddr <= oki1RomAddr[7:0];
      else if (oki1RomDataValid)
        debugLastOkiRomAddr <= oki1MappedAddr[23:16];

      if (debugOki1RomDataValid) begin
        debugLastOkiRomData <= oki1RomData;
      end

      if (mazingerZ80 & z80RomRead & z80RomValid) begin
        debugLastZ80RomAddrHi <= cpuAddr[15:8];
        debugLastZ80RomAddrLo <= cpuAddr[7:0];
        debugLastZ80RomData <= romOrBankDout;
      end
`endif

      if (z80Game & (cpuIoAddr == 16'h0000) & z80IoWrPulse)
        z80BankReg <=
          airFamilyZ80Sound ? cpuDout[4:0] :
          mazingerZ80 ? {2'b00, cpuDout[2:0]} :
                        {1'b0, cpuDout[3:0]};

      if (oki0BankWrite) begin
        oki0BankHiReg <= cpuDout[7:4];
        oki0BankLoReg <= cpuDout[3:0];
      end

      if (oki1BankWrite) begin
        if (airFamilyZ80Sound) begin
          oki1BankHiReg <= cpuDout[7:4];
          oki1BankLoReg <= cpuDout[3:0];
        end
        else begin
          oki1BankHiReg <= {2'b00, cpuDout[5:4]};
          oki1BankLoReg <= {2'b00, cpuDout[1:0]};
        end
      end

      if (replyPush) begin
        replyFifo[replyWritePtr] <= cpuDout;
        replyWritePtr <= replyWritePtr + 5'd1;
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
        debugLastReply <= cpuDout;
`endif
      end

      if (replyPop)
        replyReadPtr <= replyReadPtr + 5'd1;

      case ({replyPush, replyPop})
        2'b10: replyCount <= replyCount + 6'd1;
        2'b01: replyCount <= replyCount - 6'd1;
        default: begin
        end
      endcase
    end

    if (io_ctrl_req)
      dataReg <= io_ctrl_data;

    if (ymzAudioValid)
      ymzAudioReg <= ymzAudio;

    if (ym2203AudioValid) begin
      ym2203PsgAudioReg <= ym2203PsgAudio;
      ym2203FmAudioReg <= ym2203FmAudio;
    end

    if (ym2151AudioValid)
      ym2151AudioReg <= ym2151Audio;

    if (oki0AudioValid)
      oki0AudioReg <= oki0Audio;

    if (oki1AudioValid)
      oki1AudioReg <= oki1Audio;
  end

  CaveSoundZ80Cpu cpu (
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
    .io_fast_clock (airFamilyZ80Sound),
    .io_wait_n (z80WaitN),
    .io_int  (cpuInt),
    .io_nmi  (reqReg)
  );

  CaveSinglePortRam #(
    .ADDR_WIDTH  (13),
    .DATA_WIDTH  (8),
    .DEPTH       (0),
    .MASK_ENABLE (0)
  ) soundRam (
    .clock (clock),
    .rd    (soundRamRd),
    .wr    (soundRamWr),
    .addr  (cpuAddr[12:0]),
    .mask  (1'b0),
    .din   (cpuDout),
    .dout  (soundRamDout)
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

  CaveOKIM6295 oki_0 (
    .clock           (clock),
    .reset           (reset),
    .io_cen_step     (oki0CenStep),
    .io_cpu_wr       (oki0CpuWr),
    .io_cpu_din      (oki0CpuDin),
    .io_stretch_cpu_wr (airFamilyZ80Sound),
    .io_wait_for_rom (airFamilyZ80Sound),
    .io_cpu_dout     (oki0CpuDout),
    .io_rom_rd       (oki0RomRead),
    .io_rom_addr     (oki0RomAddr),
    .io_rom_dout     (oki0RomData),
    .io_rom_valid    (oki0RomDataValid),
    .io_audio_valid  (oki0AudioValid),
    .io_audio_bits   (oki0Audio)
  );

  CaveOKIM6295 #(
    .INTERPOL (2)
  ) oki_1 (
    .clock           (clock),
    .reset           (reset),
    .io_cen_step     (oki1CenStep),
    .io_cpu_wr       (oki1CpuWr),
    .io_cpu_din      (oki1CpuDin),
    .io_stretch_cpu_wr (airFamilyZ80Sound),
    .io_wait_for_rom (mazingerZ80 | airFamilyZ80Sound),
    .io_cpu_dout     (oki1CpuDout),
    .io_rom_rd       (oki1RomRead),
    .io_rom_addr     (oki1RomAddr),
    .io_rom_dout     (oki1RomData),
    .io_rom_valid    (oki1RomDataValid),
    .io_audio_valid  (oki1AudioValid),
    .io_audio_bits   (oki1Audio)
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
    .io_cpu_wr         (ym2203Write),
    .io_cpu_addr       (cpuAddr[0]),
    .io_cpu_din        (cpuDout),
    .io_cpu_dout       (ym2203CpuDout),
    .io_irq            (ym2203Irq),
    .io_audio_valid    (ym2203AudioValid),
    .io_audio_bits_psg (ym2203PsgAudio),
    .io_audio_bits_fm  (ym2203FmAudio)
  );

  YM2151 ym2151 (
    .clock          (clock),
    .reset          (reset),
    .io_cpu_wr      (airYm2151Write),
    .io_cpu_addr    (cpuAddr[0]),
    .io_cpu_din     (cpuDout),
    .io_cpu_dout    (ym2151CpuDout),
    .io_irq         (ym2151Irq),
    .io_audio_valid (ym2151AudioValid),
    .io_audio_bits  (ym2151Audio)
  );

  CaveSoundRomReadArbiter arbiter (
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
    .io_in_2_rd     (z80ProgRomArbiterRead),
    .io_in_2_addr   ({9'h000, cpuAddr}),
    .io_in_2_dout   (progRomDout),
    .io_in_2_valid  (progRomValid),
    .io_in_3_rd     (z80BankRomArbiterRead),
    .io_in_3_addr   ({6'h00, z80BankReg, cpuAddr[13:0]}),
    .io_in_3_dout   (bankRomDout),
    .io_in_3_valid  (bankRomValid),
    .io_out_rd      (io_rom_0_rd),
    .io_out_addr    (io_rom_0_addr),
    .io_out_dout    (io_rom_0_dout),
    .io_out_wait_n  (io_rom_0_wait_n),
    .io_out_valid   (io_rom_0_valid)
  );

  wire [15:0] fmMixInput = airFamilyZ80Sound ? ym2151AudioReg : ym2203FmAudioReg;
  wire [15:0] psgMixInput = airFamilyZ80Sound ? 16'h0000 : ym2203PsgAudioReg;

  AudioMixer io_audio_mixer (
    .clock   (clock),
    .io_airgallet (airFamilyZ80Sound),
    .io_mazinger (mazingerZ80),
    .io_in_4 (oki1AudioReg),
    .io_in_3 (oki0AudioReg),
    .io_in_2 (fmMixInput),
    .io_in_1 (psgMixInput),
    .io_in_0 (ymzAudioReg),
    .io_out  (io_audio)
  );

  assign cpuInt = airFamilyZ80Sound ? ym2151Irq : ym2203Irq;

  assign io_ctrl_oki_0_dout = {8'h00, oki0CpuDout};
  assign io_ctrl_oki_1_dout = {8'h00, oki1CpuDout};
  assign io_ctrl_ymz_dout = {8'h00, ymzCpuDout};
  assign io_ctrl_reply = (replyCount == 6'd0) ? 16'h00ff : {8'h00, replyFifo[replyReadPtr]};
`ifdef CAVE_ENABLE_DEBUG_OVERLAY
  wire [7:0] debugH0 = mazingerZ80 ? oki1CpuDout : debugLastYmAddr;
  wire [7:0] debugH1 = mazingerZ80 ? oki1AudioReg[13:6] : debugLastYmData;
  wire [7:0] debugH2 = debugFlags;
  wire [7:0] debugStartOrLatch = mazingerZ80 ? debugLastOkiStart : debugLastOkiStart;

  wire [63:0] debugCommandBits = {
    debugH2,
    debugH1,
    debugH0,
    debugStartOrLatch,
    debugLastOkiPhrase,
    debugLastOkiBank,
    debugLastReply,
    debugLastSoundCommand
  };

  assign io_debug = debugCommandBits;
`else
  assign io_debug = 64'd0;
`endif
  assign io_rom_1_rd =
    airFamilyZ80Sound ? oki0RomRead :
                         1'b1;
  assign io_rom_1_addr =
    airFamilyZ80Sound ? airOki0MappedAddr :
                   oki1MappedAddr;
  assign io_rom_2_rd = airFamilyZ80Sound & oki1RomRead;
  assign io_rom_2_addr = airOki1MappedAddr;
endmodule
