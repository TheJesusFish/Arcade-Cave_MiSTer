local machine = manager.machine
local maincpu = machine.devices[":maincpu"]
local program = maincpu.spaces["program"]

local probes = {
	0x10008a, 0x1000e8, 0x100292, 0x10029c,
	0x1002c4, 0x1002e2, 0x110000, 0x410000,
	0x510000, 0x908000
}
local frame = 0

local function dump_probe(frame)
	print(string.format("AGALLET_PROBE frame=%d", frame))
	for _, addr in ipairs(probes) do
		local ok, value = pcall(function() return program:read_u16(addr) end)
		if ok then
			print(string.format("  %06x=%04x", addr, value))
		else
			print(string.format("  %06x=ERR", addr))
		end
	end
end

emu.add_machine_frame_notifier(function()
	frame = frame + 1
	if frame == 1 or frame == 2 or frame == 4 or frame == 8 or frame == 16 or
	   frame == 32 or frame == 64 or frame == 128 or frame == 256 then
		dump_probe(frame)
	end
	if frame == 300 then
		machine:exit()
	end
end)
