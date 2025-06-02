-- scripts/bot_base.lua
local Direction = require("scripts/libs/direction")
local BotMovementHelper = require("scripts/bot_movement_helper") -- Assuming BotMovementHelper is loaded successfully

local BotBase = {}
BotBase.__index = BotBase -- For metatable-based object orientation (optional but good practice)

local all_active_bots = {} -- Stores all active bot instances by their bot_id

-- Parses an action string into a command table. (Same as before)
local function parse_action_string(action_str)
    local move_cmd, move_dir, move_dist = action_str:match("^(move)%s+([%a]+)%s+([%d%.]+)$")
    if move_cmd then return { command = "move", direction_str = string.lower(move_dir), distance = tonumber(move_dist) } end
    local wait_cmd, wait_time = action_str:match("^(wait)%s+([%d%.]+)$")
    if wait_cmd then return { command = "wait", time = tonumber(wait_time) } end
    if string.lower(action_str) == "loop" then return { command = "loop" } end
    print("BOT_BASE WARNING: Could not parse action string: '" .. action_str .. "'")
    return nil
end

--- Creates a new bot instance.
-- @param config table The specific configuration for this bot (ACTION_LIST, BOT_SETUP_CONFIG contents)
function BotBase.new(config)
    local instance = setmetatable({}, BotBase)

    instance.config = config -- Store the provided config (includes dialogue, action list, etc.)
    
    local initial_pos_obj = Net.get_object_by_name(instance.config.area_id, instance.config.spawn_object_name)
    if not initial_pos_obj then
        print("BOT_BASE ERROR: Spawn object '" .. instance.config.spawn_object_name .. "' not found for bot '" .. instance.config.bot_name .. "'.")
        return nil
    end

    local bot_id_from_net = Net.create_bot({
        name = instance.config.bot_name, area_id = instance.config.area_id,
        texture_path = instance.config.texture_path, animation_path = instance.config.animation_path,
        x = initial_pos_obj.x, y = initial_pos_obj.y, z = initial_pos_obj.z, solid = true
    })

    if not bot_id_from_net then
        print("BOT_BASE ERROR: Failed to create bot entity for '" .. instance.config.bot_name .. "'.")
        return nil
    end

    instance.bot_object = BotMovementHelper.create_bot_object(
        bot_id_from_net, initial_pos_obj,
        { area_id = instance.config.area_id, mug_texture_path = instance.config.mug_texture_path,
          mug_animation_path = instance.config.mug_animation_path, speed = instance.config.speed,
          size = instance.config.bot_collision_size }
    )

    if not instance.bot_object then
         print("BOT_BASE ERROR: Failed to create bot_object state for '" .. instance.config.bot_name .. "'.")
         -- Potentially destroy the Net.created_bot if cleanup is needed
         return nil
    end

    -- Action processing state for this instance
    instance.current_action_index = 1
    instance.current_action_data = nil
    instance.is_processing_action = false
    instance.action_list_paused = false
    instance.interacting_player_id = nil

    all_active_bots[bot_id_from_net] = instance -- Register this bot instance
    print("BOT_BASE: Initialized bot '" .. instance.config.bot_name .. "' with ID: " .. instance.bot_object.id)
    
    -- Start its first action if not paused
    if not instance.action_list_paused then
        instance:process_next_action() -- Call as a method
    end
    return instance
end

--- Method to process the next action for a bot instance.
function BotBase:process_next_action()
    if self.current_action_index > #self.config.ACTION_LIST then
        self.is_processing_action = false; self.current_action_data = nil; return
    end
    local action_string = self.config.ACTION_LIST[self.current_action_index]
    if not action_string then
        self.current_action_index = self.current_action_index + 1; self.is_processing_action = false; return
    end

    local parsed_action = parse_action_string(action_string)
    if not parsed_action then
        self.current_action_index = self.current_action_index + 1; self.is_processing_action = false; return
    end

    self.current_action_data = parsed_action

    if parsed_action.command == "move" then
        local destination = BotMovementHelper.calculate_action_destination(self.bot_object.current_tile_pos, parsed_action.direction_str, parsed_action.distance)
        if destination then
            self.bot_object.walk_target = destination; self.bot_object.walking = true; self.is_processing_action = true
        else
            print("BOT_BASE (" .. self.config.bot_name .. "): Move target for '" .. action_string .. "' is invalid/blocked. Skipping.")
            self.is_processing_action = false; self.current_action_data = nil
        end
        self.current_action_index = self.current_action_index + 1
    elseif parsed_action.command == "wait" then
        self.current_action_data.time_remaining = parsed_action.time; self.is_processing_action = true
        self.current_action_index = self.current_action_index + 1
    elseif parsed_action.command == "loop" then
        self.current_action_index = 1; self.is_processing_action = false; self.current_action_data = nil
    else
        self.current_action_index = self.current_action_index + 1; self.is_processing_action = false; self.current_action_data = nil
    end
end

--- Method to handle actor interaction for a bot instance.
function BotBase:handle_interaction(event_player_id)
    if self.interacting_player_id ~= nil then
        if self.interacting_player_id == event_player_id then return -- Redundant event
        else
            Net.message_player(event_player_id, self.config.dialogue_busy, self.bot_object.mug_texture_path, self.bot_object.mug_animation_path)
            return
        end
    end

    self.interacting_player_id = event_player_id
    self.action_list_paused = true
    print("BOT_BASE (" .. self.config.bot_name .. "): Interaction started with " .. event_player_id .. ". Pausing actions.")

    Net.lock_player_input(self.interacting_player_id)
    local bot_actual_pos = Net.get_bot_position(self.bot_object.id) or self.bot_object.current_tile_pos
    local player_pos = Net.get_player_position(self.interacting_player_id)
    if player_pos and bot_actual_pos then
        Net.set_bot_direction(self.bot_object.id, Direction.from_points(bot_actual_pos, player_pos))
    end

    local self_instance = self -- Capture for the .and_then closure
    Async.question_player(self.interacting_player_id,
        self.config.dialogue_main_prompt,
        self.bot_object.mug_texture_path,
        self.bot_object.mug_animation_path
    )
    .and_then(function(response_code)
        local player_who_finished = self_instance.interacting_player_id -- Should be the same as self.interacting_player_id

        local pcall_ok, err_msg = pcall(function()
            if response_code == nil then return end
            local response_category = BotMovementHelper.process_interaction_outcome(self_instance.bot_object, response_code)
            local message_to_send
            if response_category == "positive" then message_to_send = self_instance.config.dialogue_response_positive
            else message_to_send = self_instance.config.dialogue_response_negative end
            Net.message_player(player_who_finished, message_to_send, self_instance.bot_object.mug_texture_path, self_instance.bot_object.mug_animation_path)
        end)

        Net.unlock_player_input(player_who_finished)
        if self_instance.interacting_player_id == player_who_finished then
            self_instance.interacting_player_id = nil
        end
        self_instance.action_list_paused = false
        print("BOT_BASE (" .. self_instance.config.bot_name .. "): Interaction ended with " .. player_who_finished .. ". Resuming actions.")
        if not pcall_ok then print("BOT_BASE ERROR (" .. self_instance.config.bot_name .. "): Dialogue processing: " .. tostring(err_msg)) end
    end)
end

--- Method to update a bot instance on tick.
function BotBase:update_tick(dt)
    if self.action_list_paused then return end

    if self.is_processing_action then
        if self.bot_object.walking then
            BotMovementHelper.update_movement_on_tick(self.bot_object, dt, Net)
            if not self.bot_object.walking then self.is_processing_action = false; self.current_action_data = nil end
        elseif self.current_action_data and self.current_action_data.command == "wait" then
            self.current_action_data.time_remaining = self.current_action_data.time_remaining - dt
            if self.current_action_data.time_remaining <= 0 then self.is_processing_action = false; self.current_action_data = nil end
        end
    end

    if not self.is_processing_action then
        self:process_next_action()
    end
end


-- Global Event Handlers (These will dispatch to the correct bot instance)
Net:on("actor_interaction", function(event)
    local bot_instance = all_active_bots[event.actor_id]
    if bot_instance then
        bot_instance:handle_interaction(event.player_id)
    end
end)

Net:on("tick", function(event)
    local dt = event.delta_time
    for bot_id, bot_instance in pairs(all_active_bots) do
        bot_instance:update_tick(dt)
    end
end)

print("BOT_BASE: System initialized. Ready to create bot instances.")
return BotBase