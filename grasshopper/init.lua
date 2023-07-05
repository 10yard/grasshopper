-- Grasshopper plugin for Centipede 
-- by Jon Wilson (10yard)
--
-- Inspired by the GenXGrownUp short video at https://www.youtube.com/shorts/2NThBgP-mlc
-- The unused grasshopper sprite becomes active.  
--
-- The grasshopper has 50% chance of appearing instead of the spider. It occupies the lower section he screen and has its own unique sound.
--
-- Tested with latest MAME version 0.254
-- Compatible with MAME versions from 0.241
--
-- Minimum start up arguments:
--   mame centiped -plugin grasshopper

local exports = {}
exports.name = "grasshopper"
exports.version = "0.1"
exports.description = "Grasshopper plugin for Centipede"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local grasshopper = exports

local ypos = 0
local flip = 0
local active

function grasshopper.startplugin()	
	
	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.241 then
			mac = manager.machine
		else	
			print("ERROR: The grasshopper plugin requires MAME version 0.241 or greater.")
		end
		if mac ~= nil then
			maincpu = mac.devices[":maincpu"]
			mem = maincpu.spaces["program"]
			scr = mac.screens[":screen"]
			mem:install_read_tap(0x07dd, 0x07dd, "Set Active Sprite", set_active_sprite)
			mem:install_write_tap(0x0071, 0x0071, "Update Sprite Position", update_sprite_position)
			mem:install_write_tap(0x00b5, 0x00b5, "Update Sprite Sound", update_sprite_sound)
			mem:install_write_tap(0x07cd, 0x07cd, "Update Sprite Graphic", update_sprite_graphic)
		end
	end

	function set_active_sprite(address, value)
		-- 50% chance of the grasshopper becoming active (instead of spider)
		-- grasshopper always comes out first.
		if value == 1 or value == 254 then
			if math.random(2) == 1 or active == nil then
				active = true
				featuring_grasshopper()
				-- flip sprite based on what side of screen it emerges
				if value == 0 then flip = 0	elseif value == 255 then flip = 128	end
			else
				active = false
			end
		end
	end


	function update_vert_velocity(address, value)
		if active then
			return 0
		end
	end

	function update_sprite_graphic(address, value)
		-- if grasshopper sprite is active then update the graphics and behaviour
		if active then
			local _sprite = tonumber("00111111", 2) & value  -- ignore bits 6 and 7
			if _sprite >= 0x14 and _sprite <= 0x1b then
				return 0x2c + ((0x1b - _sprite) % 4) + flip  -- swap graphics and flip if necessary
			end
		end	
	end

	function update_sprite_position(address, value)
	-- The grasshopper stays lower with constrained vertical movement
		if active then
			ypos = value
			if ypos > 45 then ypos = 45 end
			return ypos
		end
	end

	function update_sprite_sound(address, value)
		-- Adjust sound of the grasshopper
		if active then
			return value / 2
		end
	end


	function featuring_grasshopper()
		-- Display "FEATURING GRASSHOPPER" during attract mode
		if mem:read_u8(0x540) == 0x1b then
			local _text = {
				0x06, 0x05, 0x01, 0x14, 0x15, 0x12, 0x09, 0x0e, 0x07, 
				0x00, 0x07, 0x12, 0x01, 0x13, 0x13, 0x08, 0x0f, 0x10, 0x10, 0x05, 0x12}
			for k, v in ipairs(_text) do			
				mem:write_u8(0x048e + (0x20 * k), v)
			end
		end
	end

	emu.register_start(function()
		initialize()
	end)		
end
return exports