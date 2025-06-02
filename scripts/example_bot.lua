-- --example_bot.lua

-- -- Main Bot Script (Action List with Interaction Pause & Busy Message)
-- local Direction = require("scripts/libs/direction")

-- local load_success, BotMovementHelper = pcall(require, "scripts/bot_movement_helper")
-- if not load_success or not BotMovementHelper then
--     print("FATAL ERROR: BotMovementHelper could not be loaded. Error: " .. tostring(BotMovementHelper))
--     return
-- end


-- local ACTION_LIST = {
--     "move south 2",
--     "wait 2.0",
--     "move east 2",
--     "move north 1",
--     "move east 1",
--     "wait 1.5",
--     "move north 2",
--     "move west 3",
--     "move south 1",
--     "loop"
-- }
-- local BOT_SETUP_CONFIG = {
--     area_id = "default",
--     spawn_object_name = "Bot Spawn",
--     bot_name = "PoliteActionBot", -- Updated name
--     texture_path = "/server/assets/prog.png",
--     animation_path = "/server/assets/prog.animation",
--     mug_texture_path = "resources/ow/prog/prog_mug.png",
--     mug_animation_path = "resources/ow/prog/prog_mug.animation",
--     speed = 1,
--     bot_collision_size = 0.5,
--     dialogue_main_prompt = "I am following my script! What do you need?",
--     dialogue_response_positive = "Glad you noticed!",
--     dialogue_response_negative = "Indeed, I am.",
--     dialogue_busy = "Sorry, I'm talking to someone else right now. Please try again in a moment!" -- New busy message
-- }

-- local initial_pos_obj = Net.get_object_by_name(BOT_SETUP_CONFIG.area_id, BOT_SETUP_CONFIG.spawn_object_name)
-- if not initial_pos_obj then print("ERROR: Spawn object not found."); return end

-- local bot_id_from_net = Net.create_bot({
--     name = BOT_SETUP_CONFIG.bot_name, area_id = BOT_SETUP_CONFIG.area_id,
--     texture_path = BOT_SETUP_CONFIG.texture_path, animation_path = BOT_SETUP_CONFIG.animation_path,
--     x = initial_pos_obj.x, y = initial_pos_obj.y, z = initial_pos_obj.z, solid = true
-- })
-- if not bot_id_from_net then print("ERROR: Failed to create bot."); return end

-- local bot_object = BotMovementHelper.create_bot_object(
--     bot_id_from_net, initial_pos_obj,
--     { area_id = BOT_SETUP_CONFIG.area_id, mug_texture_path = BOT_SETUP_CONFIG.mug_texture_path,
--       mug_animation_path = BOT_SETUP_CONFIG.mug_animation_path, speed = BOT_SETUP_CONFIG.speed,
--       size = BOT_SETUP_CONFIG.bot_collision_size }
-- )

-- -- Action processing state
-- local current_action_index = 1
-- local current_action_data = nil
-- local is_processing_action = false
-- local action_list_paused = false
-- local interacting_player_id = nil -- <<< NEW: Tracks who the bot is talking to

-- function parse_action_string(action_str)
--     local move_cmd, move_dir, move_dist = action_str:match("^(move)%s+([%a]+)%s+([%d%.]+)$")
--     if move_cmd then return { command = "move", direction_str = string.lower(move_dir), distance = tonumber(move_dist) } end
--     local wait_cmd, wait_time = action_str:match("^(wait)%s+([%d%.]+)$")
--     if wait_cmd then return { command = "wait", time = tonumber(wait_time) } end
--     if string.lower(action_str) == "loop" then return { command = "loop" } end
--     print("BOT SCRIPT WARNING: Could not parse action string: '" .. action_str .. "'")
--     return nil
-- end

-- function process_next_action_from_list()
--     if current_action_index > #ACTION_LIST then
--         is_processing_action = false; current_action_data = nil; return
--     end
--     local action_string = ACTION_LIST[current_action_index]
--     if not action_string then
--         current_action_index = current_action_index + 1; is_processing_action = false; return
--     end
--     local parsed_action = parse_action_string(action_string)
--     if not parsed_action then
--         current_action_index = current_action_index + 1; is_processing_action = false; return
--     end
--     current_action_data = parsed_action
--     if parsed_action.command == "move" then
--         local destination = BotMovementHelper.calculate_action_destination(bot_object.current_tile_pos, parsed_action.direction_str, parsed_action.distance)
--         if destination then
--             bot_object.walk_target = destination; bot_object.walking = true; is_processing_action = true
--         else
--             print("BOT SCRIPT WARNING: Move target for '" .. action_string .. "' is invalid/blocked. Skipping.")
--             is_processing_action = false; current_action_data = nil
--         end
--         current_action_index = current_action_index + 1
--     elseif parsed_action.command == "wait" then
--         current_action_data.time_remaining = parsed_action.time; is_processing_action = true
--         current_action_index = current_action_index + 1
--     elseif parsed_action.command == "loop" then
--         current_action_index = 1; is_processing_action = false; current_action_data = nil
--     else
--         current_action_index = current_action_index + 1; is_processing_action = false; current_action_data = nil
--     end
-- end

-- -- Event Handler: Actor Interaction
-- Net:on("actor_interaction", function(event)
--     if event.actor_id ~= bot_object.id then return end

--     local new_player_id = event.player_id -- Player attempting this interaction

--     -- <<< NEW BUSY CHECK >>>
--     if interacting_player_id ~= nil then
--         if interacting_player_id == new_player_id then
--             -- This player is somehow re-triggering interaction while already in one.
--             -- This case should be rare if input is locked. We can just ignore.
--             print("BOT SCRIPT: Player " .. new_player_id .. " sent redundant interaction event.")
--             return
--         else
--             -- Bot is busy with someone else.
--             print("BOT SCRIPT: Bot is busy with " .. interacting_player_id .. ". Sending busy message to " .. new_player_id)
--             Net.message_player(new_player_id, BOT_SETUP_CONFIG.dialogue_busy, bot_object.mug_texture_path, bot_object.mug_animation_path)
--             return -- Do not proceed with this new player's interaction
--         end
--     end
--     -- <<< END OF BUSY CHECK >>>

--     -- If not busy, this new_player_id becomes the interacting_player_id
--     interacting_player_id = new_player_id
--     print("BOT SCRIPT: Interaction started with player " .. interacting_player_id .. ". Pausing action list.")
--     action_list_paused = true

--     Net.lock_player_input(interacting_player_id) -- Lock the input of the current interactor

--     local bot_actual_pos = Net.get_bot_position(bot_object.id) or bot_object.current_tile_pos
--     local player_pos = Net.get_player_position(interacting_player_id)
--     if player_pos and bot_actual_pos then
--         Net.set_bot_direction(bot_object.id, Direction.from_points(bot_actual_pos, player_pos))
--     end

--     Async.question_player(interacting_player_id,
--         BOT_SETUP_CONFIG.dialogue_main_prompt,
--         bot_object.mug_texture_path,
--         bot_object.mug_animation_path
--     )
--     .and_then(function(response_code)
--         -- This callback is for the player who was stored in 'interacting_player_id' when Async.question_player was called
--         local player_who_finished_interaction = interacting_player_id 
--                                                 -- It's good practice to use the ID that was current when the async operation started,
--                                                 -- especially if 'interacting_player_id' could somehow change due to other rapid events (though unlikely here).
--                                                 -- For this flow, interacting_player_id should still be player_who_finished_interaction.

--         local pcall_ok, err_msg = pcall(function()
--             if response_code == nil then
--                 print("BOT SCRIPT: Player " .. player_who_finished_interaction .. " disconnected mid-prompt.")
--                 return -- Dialogue logic skipped
--             end
--             local response_category = BotMovementHelper.process_interaction_outcome(bot_object, response_code)
--             local message_to_send
--             if response_category == "positive" then message_to_send = BOT_SETUP_CONFIG.dialogue_response_positive
--             else message_to_send = BOT_SETUP_CONFIG.dialogue_response_negative end
--             Net.message_player(player_who_finished_interaction, message_to_send, bot_object.mug_texture_path, bot_object.mug_animation_path)
--         end)

--         Net.unlock_player_input(player_who_finished_interaction)
        
--         -- Critical: Only clear interacting_player_id if it's still the one this callback was for.
--         if interacting_player_id == player_who_finished_interaction then
--             interacting_player_id = nil
--             print("BOT SCRIPT: Bot is no longer busy with " .. player_who_finished_interaction .. ".")
--         end
        
--         action_list_paused = false
--         print("BOT SCRIPT: Interaction sequence finished for " .. player_who_finished_interaction .. ". Action list resumed.")

--         if not pcall_ok then print("ERROR in dialogue processing for player " .. player_who_finished_interaction .. ": " .. tostring(err_msg)) end
--     end)
-- end)

-- -- Event Handler: Server Tick (Action Processing Engine)
-- Net:on("tick", function(event)
--     local dt = event.delta_time
--     if not bot_object or not bot_id_from_net then return end

--     if action_list_paused then return end -- If paused, do nothing with actions

--     if is_processing_action then
--         if bot_object.walking then
--             BotMovementHelper.update_movement_on_tick(bot_object, dt, Net)
--             if not bot_object.walking then is_processing_action = false; current_action_data = nil end
--         elseif current_action_data and current_action_data.command == "wait" then
--             current_action_data.time_remaining = current_action_data.time_remaining - dt
--             if current_action_data.time_remaining <= 0 then is_processing_action = false; current_action_data = nil end
--         end
--     end

--     if not is_processing_action then
--         process_next_action_from_list()
--     end
-- end)

-- print("Bot Script Initialized (Action List with Busy Message) for bot ID: " .. tostring(bot_object.id))
-- if not action_list_paused then process_next_action_from_list() end