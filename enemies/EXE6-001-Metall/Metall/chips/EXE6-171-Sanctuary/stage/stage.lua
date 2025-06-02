local print_debug = false

local STAGE_AUDIO1 = Engine.load_audio(_folderpath.."sfx/EXE6_173.ogg", true)
local STAGE_AUDIO2 = Engine.load_audio(_folderpath.."sfx/EXE4_136.ogg", true)

local function debug_print(text)
    if print_debug then
        print("[Stage] "..text)
    end
end

local stage = {}

stage.card_create_action = function(user, props)
    debug_print("in create_card_action()!")
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
	action.execute_func = function(self, user)
        debug_print("in custom card action execute_func()!")
        local tile_count = 0
		local other_tile_count = 0
		local facing = user:get_facing()
		local field = user:get_field()
		local tile1 = user:get_tile(facing, 1)
		local all_red_tiles = field:find_tiles(function(tile) 
			if tile:get_team() == user:get_team() then 
				tile_count = tile_count+1
				return true 
			end
			return false
		end)
		local k = 0
		local cooldown = 0
		local is_reveal = false
		local original_state_table = {}
		local other_tile_original_state_table = {}
		local original_state_table1 = {}
		local step1 = Battle.Step.new()
		local do_once = true
		step1.update_func = function(self, dt)
			if cooldown <= 0 then
				k = k + 1
				cooldown = 0.033
				if do_once then
					do_once = false
					if stage.type == 1 then
						table.insert(original_state_table1, tile1:get_state())
					else
						for i = 1, tile_count, 1 do
							table.insert(original_state_table, all_red_tiles[i]:get_state())
						end
					end
				end
				Engine.play_audio(STAGE_AUDIO1, AudioPriority.Highest)
				if is_reveal then
					is_reveal = false
					if stage.type == 1 then
						tile1:set_state(original_state_table1[1])
					else
						for j = 1, tile_count, 1 do
							all_red_tiles[j]:set_state(original_state_table[j])
						end
					end
				else
					is_reveal = true
					if stage.type == 1 then
						tile1:set_state(TileState.Holy)
					else
						for j = 1, tile_count, 1 do
							if		stage.type == 0 then
								all_red_tiles[j]:set_state(TileState.Normal)
							elseif	stage.type == 2 then
								all_red_tiles[j]:set_state(TileState.Holy)
							end
						end
					end
				end
			else
				cooldown = cooldown - dt
			end
			if k == 17 then
				Engine.play_audio(STAGE_AUDIO2, AudioPriority.High)
				self:complete_step()
			end	
		end
		self:add_step(step1)
	end
	return action
end

return stage