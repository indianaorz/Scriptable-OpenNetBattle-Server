--Functions for easy reuse in scripts
--Version 1.1

---@class BattleHelper
battle_helpers = {}

-- This function returns a target enemy.
function battle_helpers.find_target(self)
    local field = self:get_field()
    local team = self:get_team()
    local target_list = field:find_characters(function(other_character)
        return other_character:get_team() ~= team
    end)
    if #target_list == 0 then
        --print("No targets found!")
        return
    end
    local target_character = target_list[1]
    return target_character
end

-- This function spawns a visual effect that will remove itself once the effect animation completes.
function battle_helpers.spawn_visual_artifact(field, tile, texture, animation_path, animation_state, position_x,
                                              position_y)
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(texture, true)
    local anim = visual_artifact:get_animation()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:sprite():set_offset(position_x, position_y)
    anim:refresh(visual_artifact:sprite())
    field:spawn(visual_artifact, tile:x(), tile:y())
end

-- This function returns true if the entity can move to the tile, false otherwise.
battle_helpers.can_move_to_func = function(tile, entity)
    if not tile:is_walkable() or tile:get_team() ~= entity:get_team() or
        tile:is_reserved({ entity:get_id(), entity._reserver }) then
        return false
    end

    local has_character = false

    tile:find_characters(function(c)
        if c:get_id() ~= entity:get_id() then
            has_character = true
        end
        return false
    end)
    tile:find_obstacles(function(c)
        if c:get_id() ~= entity:get_id() then
            has_character = true
        end
        return false
    end)
    return not has_character
end

-- This function returns true if the entity can move to the tile, false otherwise.
-- Expanded to ignore team and walkability
battle_helpers.can_move_to_func_expanded = function(tile, entity)
    if tile:is_reserved({ entity:get_id(), entity._reserver }) then
        return false
    end

    local has_character = false

    tile:find_characters(function(c)
        if c:get_id() ~= entity:get_id() then
            has_character = true
        end
        return false
    end)
    tile:find_obstacles(function(c)
        if c:get_id() ~= entity:get_id() then
            has_character = true
        end
        return false
    end)
    return not has_character
end

--- Moves character in front of enemy as close as possible.
---@param character any
---@param enemy_char any
---@return boolean
function battle_helpers.move_in_front_of_enemy(character, enemy_char)
    local field = character:get_field()
    local my_tile = character:get_tile()
    local available_tiles = {}

    -- add tiles in row from enemy char to end of field
    local check_col = enemy_char:get_tile(enemy_char:get_facing(), 1):x()
    local check_tile = field:tile_at(check_col, 1)
    table.insert(available_tiles, enemy_char:get_tile(enemy_char:get_facing(), 1))
    while not check_tile:is_edge() do
        table.insert(available_tiles, check_tile)
        check_tile = check_tile:get_tile(Direction.Down, 1)
    end

    for index, prospective_tile in ipairs(available_tiles) do
        if battle_helpers.can_move_to_func_expanded(prospective_tile, character) then
            character:teleport(prospective_tile, ActionOrder.Immediate)

            return true
        end
    end
    return false
end

function Tiletostring(tile)
    return "Tile: [" .. tostring(tile:x()) .. "," .. tostring(tile:y()) .. "]"
end

function battle_helpers.move_at_random(character)

    local field = character:get_field()
    local my_tile = character:get_tile()
    local tile_array = {}
    for x = 1, 6, 1 do
        for y = 1, 3, 1 do
            local prospective_tile = field:tile_at(x, y)
            if battle_helpers.can_move_to_func(prospective_tile, character) and
                my_tile ~= prospective_tile then
                table.insert(tile_array, prospective_tile)
            end
        end
    end

    if #tile_array == 0 then return false end
    target_tile = tile_array[math.random(1, #tile_array)]
    if target_tile then
        moved = character:teleport(target_tile, ActionOrder.Immediate)
    end
    return moved
end

function battle_helpers.move_at_random_avoid_same_row(character)

    local field = character:get_field()
    local my_tile = character:get_tile()
    local tile_array = {}
    for x = 1, 6, 1 do
        for y = 1, 3, 1 do
            local prospective_tile = field:tile_at(x, y)
            if battle_helpers.can_move_to_func(prospective_tile, character) and
                my_tile ~= prospective_tile and prospective_tile:y() ~= my_tile:y() then
                table.insert(tile_array, prospective_tile)
            end
        end
    end

    if #tile_array == 0 then return false end
    target_tile = tile_array[math.random(1, #tile_array)]
    if target_tile then
        moved = character:teleport(target_tile, ActionOrder.Immediate)
    end
    return moved
end

return battle_helpers
