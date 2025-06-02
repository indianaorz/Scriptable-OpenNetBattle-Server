-- scripts/bot_movement_helper.lua
local math = require("math")

local ezhelpers_load_status, ezhelpers = pcall(require, "scripts/ezlibs-scripts/helpers")
if not ezhelpers_load_status or not ezhelpers then
    print("HELPER WARNING: Could not load 'scripts/ezlibs-scripts/helpers.lua'. Player overlap checks may not work. Error: " .. tostring(ezhelpers))
    ezhelpers = {}
end

local BotMovementHelper = {}

BotMovementHelper.DEFAULT_SPEED = 2
BotMovementHelper.ARRIVAL_THRESHOLD_SQ = 0.0025

-- Internal: Cardinal directions for movement actions. NOTE: Keys are UPPERCASE.
local DIRECTIONS = {
    NORTH = {x=0, y=-1, z=0},
    SOUTH = {x=0, y=1,  z=0},
    EAST  = {x=1, y=0,  z=0},
    WEST  = {x=-1, y=0, z=0},
    UP    = {x=0, y=0,  z=1},  -- Example if you want Z movement
    DOWN  = {x=0, y=0,  z=-1}  -- Example if you want Z movement
}
-- Note: Current _calculate_target_position for random moves uses a different DIRECTIONS list.
-- This new DIRECTIONS table is for the action list's "move" command.

local function _get_random_direction_offset() -- Kept for potential future use, but not by action list
    local random_directions_list = {DIRECTIONS.NORTH, DIRECTIONS.SOUTH, DIRECTIONS.EAST, DIRECTIONS.WEST}
    if #random_directions_list == 0 then return {x=0,y=0,z=0} end
    return random_directions_list[math.random(#random_directions_list)]
end

local function _calculate_random_target_position(current_pos, offset) -- Renamed for clarity
    if not current_pos or not offset then return nil end
    return {x = current_pos.x + offset.x, y = current_pos.y + offset.y, z = current_pos.z + offset.z}
end

local function _step_towards_target(current_pos, target_pos, speed, dt)
    if not current_pos or not target_pos then return current_pos, current_pos, current_pos, true end
    local dx = target_pos.x - current_pos.x
    local dy = target_pos.y - current_pos.y
    local dz = target_pos.z - current_pos.z
    local dist_sq = dx*dx + dy*dy + dz*dz
    if dist_sq < BotMovementHelper.ARRIVAL_THRESHOLD_SQ then return target_pos.x, target_pos.y, target_pos.z, true end
    local dist = math.sqrt(dist_sq)
    local move_amount = speed * dt
    if move_amount >= dist then return target_pos.x, target_pos.y, target_pos.z, true end
    local norm_dx, norm_dy, norm_dz = dx/dist, dy/dist, dz/dist
    return current_pos.x + norm_dx*move_amount, current_pos.y + norm_dy*move_amount, current_pos.z + norm_dz*move_amount, false
end

-- CRITICAL: User must implement this with their engine's API for map bounds and solid terrain.
local function _is_map_tile_valid(area_id, x, y, z, Net)
    -- print("DEBUG HELPER: _is_map_tile_valid called for area '" .. area_id .. "' at (" .. x .. "," .. y .. "," .. z .. "). NEEDS IMPLEMENTATION!")
    return true -- Placeholder: Bot may still walk off map if not properly implemented.
end

local function _is_tile_walkable_and_clear(bot_object, target_x, target_y, target_z, Net)
    if not _is_map_tile_valid(bot_object.area_id, target_x, target_y, target_z, Net) then
        return false
    end
    if ezhelpers and ezhelpers.position_overlaps_something then
        local target_pos_for_overlap_check = {x = target_x, y = target_y, z = target_z, size = bot_object.size}
        if ezhelpers.position_overlaps_something(target_pos_for_overlap_check, bot_object.area_id) then
            return false
        end
    end
    return true
end

function BotMovementHelper.create_bot_object(bot_id, initial_pos, config)
    return {
        id = bot_id,
        area_id = config.area_id,
        current_tile_pos = {x = initial_pos.x, y = initial_pos.y, z = initial_pos.z},
        walk_target = nil,
        walking = false, -- This will be set to true when a "move" action is active
        speed = config.speed or BotMovementHelper.DEFAULT_SPEED,
        size = config.size or 0.5,
        mug_texture_path = config.mug_texture_path or "",
        mug_animation_path = config.mug_animation_path or ""
    }
end

---
-- Calculates a destination point based on a starting position, direction string, and distance.
-- @param start_pos table {x, y, z} The starting position.
-- @param direction_str string The direction (e.g., "north", "east"). Case-insensitive.
-- @param distance number The distance to move in that direction.
-- @return table {x, y, z} The calculated destination, or nil if direction is invalid.
function BotMovementHelper.calculate_action_destination(start_pos, direction_str, distance)
    local direction_key = string.upper(direction_str)
    local offset_vector = DIRECTIONS[direction_key]

    if not offset_vector then
        print("HELPER ERROR: Invalid direction '" .. direction_str .. "' for move action.")
        return nil
    end

    return {
        x = start_pos.x + offset_vector.x * distance,
        y = start_pos.y + offset_vector.y * distance,
        z = start_pos.z + offset_vector.z * distance -- Handles Z if DIRECTIONS vectors include Z components
    }
end

---
-- Determines the category of player's response. Does NOT trigger movement.
function BotMovementHelper.process_interaction_outcome(bot_object, response_code)
    if response_code == 1 then
        return "positive"
    else
        return "negative"
    end
    -- No movement logic here; action list controls movement.
end

function BotMovementHelper.update_movement_on_tick(bot_object, dt, Net)
    if not bot_object.walking or not bot_object.walk_target then return end
    local current_pos_actual = Net.get_bot_position(bot_object.id)
    if not current_pos_actual then
        bot_object.walking = false
        return
    end
    local nx, ny, nz, arrived = _step_towards_target(current_pos_actual, bot_object.walk_target, bot_object.speed, dt)
    if arrived then
        bot_object.walking = false
        Net.move_bot(bot_object.id, bot_object.walk_target.x, bot_object.walk_target.y, bot_object.walk_target.z)
        bot_object.current_tile_pos = {x=bot_object.walk_target.x, y=bot_object.walk_target.y, z=bot_object.walk_target.z}
        bot_object.walk_target = nil
    else
        Net.move_bot(bot_object.id, nx, ny, nz)
    end
end

return BotMovementHelper