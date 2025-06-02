-- Imports
---@type BattleHelper
local battle_helpers = include("battle_helpers.lua")
-- Animations, Textures and Sounds
local CHARACTER_ANIMATION = _folderpath .. "battle.animation"
local CHARACTER_TEXTURE = Engine.load_texture(_folderpath .. "battle.greyscaled.png")
local BUBBLESPAWN_SFX = Engine.load_audio(_folderpath .. "bubblespawn.ogg")
local BUBBLEBOUNCE_SFX = Engine.load_audio(_folderpath .. "bubblebounce.ogg")
local BUBBLEIMPACT_SFX = Engine.load_audio(_folderpath .. "bubbleimpact.ogg")
local BUBBLE_SPRITE = Engine.load_texture(_folderpath .. "bubbles.png")
local BUBBLES_ANIM = _folderpath .. "bubbles.animation"
local effects_texture = Engine.load_texture(_folderpath .. "bubbleimpact.png")
local effects_anim = _folderpath .. "bubbleimpact.animation"

--possible states for character
local states = { IDLE = 1, MOVE = 2, WAIT = 3 }
local debug = false

function debug_print(str)
    if debug then
        print("[shrimpy] " .. str)
    end
end

---@param self Entity
function package_init(self, character_info)
    -- Required function, main package information
    -- Load extra resources
    local base_animation_path = CHARACTER_ANIMATION
    self:set_texture(CHARACTER_TEXTURE)
    self.animation = self:get_animation()
    self.animation:load(base_animation_path)

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_height(character_info.height)
    self.damage = (character_info.damage)
    self:share_tile(false)
    self:set_explosion_behavior(4, 1, false)
    self:set_offset(0, 0)
    self:set_palette(Engine.load_texture(character_info.palette))
    self.shockwave_anim = character_info.shockwave_anim
    self.panelgrabs = character_info.panelgrabs
    self.bubble_speed = character_info.bubble_speed
    self.animation:set_state("SPAWN")
    self.frame_counter = 0
    self.started = false
    self.idle_frames = 8
    --Select bubble move direction
    self.move_direction = Direction.Up
    self.move_speed = character_info.move_speed
    self.defense = Battle.DefenseVirusBody.new()
    self:add_defense_rule(self.defense)
    self:set_element(Element.Aqua)
    self.reached_edge = false
    self.has_attacked_once = false
    self.guard = true


    self:set_air_shoe(true)
    self:set_float_shoe(true)

    ---state idle
    ---@param frame number
    self.action_idle = function(frame)
        if (frame == self.idle_frames) then
            ---choose move direction.
            self.animation:set_state("IDLE")
            self.animation:set_playback(Playback.Loop)
            self.set_state(states.MOVE)
        end
    end

    self.turn = function()
        debug_print("shrimpy turned")
        self.move_direction = Direction.reverse(self.move_direction)

    end

    ---state move
    ---@param frame number
    self.action_move = function(frame)
        if (frame == 1) then
            -- get target to slide to
            local target_tile = self:get_tile(self.move_direction, 1)
            debug_print("Current tile " .. Tiletostring(self:get_tile()))
            debug_print("Target = " .. Tiletostring(target_tile))
            debug_print("Direction = " .. directiontostring(self.move_direction))
            --if not free, change direction.
            if (not is_tile_free_for_movement(target_tile, self)) then
                self.turn()
                local turned_tile = self:get_tile(self.move_direction, 1)
                if (is_tile_free_for_movement(turned_tile, self)) then
                    --free to move to the turned tile, otherwise stuck.
                    self.set_state(states.MOVE)
                end
            end
            self:slide(target_tile, frames(self.move_speed), frames(0), ActionOrder.Immediate, nil)

        end
        if (frame >= self.move_speed and not self:is_sliding()) then
            debug_print(tostring(self.wait_tiles))
            if (self.wait_tiles == 0) then
                -- once shrimpy has moved enough tiles, attack
                self.bubblespell()
                self.set_state(states.WAIT)
                self.wait_tiles = math.random(2, 4)
            else
                self.wait_tiles = self.wait_tiles - 1
                self.set_state(states.MOVE)
            end
        end
    end

    ---state wait
    ---@param frame number
    self.action_wait = function(frame)
        if (frame == 12) then
            self:toggle_counter(false)
            self.set_state(states.IDLE)
        end
    end

    --utility to set the update state, and reset frame counter
    ---@param state number
    self.set_state = function(state)
        self.state = state
        self.frame_counter = 0
    end

    local actions = { [1] = self.action_idle, [2] = self.action_move, [3] = self.action_wait }

    self.update_func = function()
        self.frame_counter = self.frame_counter + 1
        if not self.started then
            --- this runs once the battle is started
            self.current_direction = self:get_facing()
            self.started = true
            self.set_state(states.IDLE)
            self.wait_tiles = math.random(2, 4)
        else
            --- On every frame, we will call the state action func.
            local action_func = actions[self.state]
            action_func(self.frame_counter)
        end
    end

    self.bubblespell = function()

        self.animation:set_state("ATTACK")


        self.has_attacked_once = true
        self.animation:on_frame(3, function()
            self.guard = false
            self:toggle_counter(true)
        end)
        self.animation:on_complete(function()
            Engine.play_audio(BUBBLESPAWN_SFX, AudioPriority.High)
            bubbles(self)
            self.set_state(states.WAIT)
        end)
    end

    function Tiletostring(tile)
        return "Tile: [" .. tostring(tile:x()) .. "," .. tostring(tile:y()) .. "]"
    end

    function directiontostring(dir)

        if dir == Direction.Up then return "Up"
        elseif dir == Direction.Down then return "Down"
        end
    end

    ---Bubbles!
    ---@param user Entity
    function bubbles(user)
        local field = user:get_field()
        ---@class Spell
        local spell = Battle.Spell.new(user:get_team())
        local spell_animation = spell:get_animation()
        local start_tile = user:get_tile(user:get_facing(), 1)
        -- Spell Hit Properties
        spell:set_hit_props(
            HitProps.new(
                user.damage,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                Element.Aqua,
                user:get_context(),
                Drag.None
            )
        )
        spell:set_facing(user:get_facing())
        spell_animation:load(BUBBLES_ANIM)
        spell_animation:set_state("BUBBLEBOUNCE")
        spell_animation:set_playback(Playback.Loop)
        spell:set_texture(BUBBLE_SPRITE)
        spell_animation:refresh(spell:sprite())
        spell:sprite():set_layer(-2)
        spell:set_shadow(Shadow.Small)
        spell:show_shadow(true)
        -- Starting direction is user's facing
        spell.direction = user:get_facing()
        spell.userfacing = user:get_facing()
        spell.bubble_speed = user.bubble_speed
        spell.next_tile = start_tile:get_tile(spell.direction, 1)
        spell.frame_count = 0
        spell.elevation = 0
        spell.update_func = function(self, dt)
            if (spell.next_tile == nil or self:get_current_tile():get_state() == TileState.Broken) or
                self:get_current_tile():get_state() == TileState.Empty then
                spell:erase()
            end
            local bounce = function()
                Engine.play_audio(BUBBLEBOUNCE_SFX, AudioPriority.Low)
            end
            if (spell.frame_count < 10) then
                spell.elevation = spell.elevation + 3
            elseif (spell.frame_count < 20) then
                spell.elevation = spell.elevation - 3
            else
                spell.elevation = 0
                spell.frame_count = 0
            end
            spell:set_elevation(spell.elevation)
            spell:slide(spell.next_tile, frames(spell.bubble_speed), frames(0), ActionOrder.Voluntary, bounce)
            spell.next_tile = spell:get_current_tile():get_tile(spell.direction, 1)
            spell:get_current_tile():attack_entities(self)
            spell.frame_count = spell.frame_count + 1
        end
        spell.collision_func = function(self, other)
        end

        -- ty dawn
        local function rank_relevant_bubbles(attack, explosion_table)
            for explosions = 1, #explosion_table, 1 do
                if (not explosion_table[explosions]:is_edge()) then
                    local hitbox = Battle.Hitbox.new(spell:get_team())
                    hitbox:set_hit_props(attack:copy_hit_props())
                    local fx = Battle.Spell.new(attack:get_team())
                    fx:set_texture(effects_texture, true)
                    local fx_anim = fx:get_animation()
                    fx_anim:load(effects_anim)
                    fx_anim:set_state("Default")
                    fx_anim:refresh(fx:sprite())
                    fx:sprite():set_layer(-2)
                    fx_anim:on_complete(function() fx:erase() end)
                    field:spawn(fx, explosion_table[explosions])
                    field:spawn(hitbox, explosion_table[explosions])
                end
            end
            attack:erase()
        end

        spell.attack_func = function(self, other)
            local bubble_tiles = {}
            local rank = user:get_rank()
            if rank == Rank.V1 or rank == Rank.SP then
                bubble_tiles = { self:get_tile(), self:get_tile(self:get_facing(), 1) }
            elseif rank == Rank.V2 or Rank == Rank.Rare1 then
                bubble_tiles = { self:get_tile(), self:get_tile(Direction.join(self:get_facing(), Direction.Up), 1),
                    self:get_tile(Direction.join(self:get_facing(), Direction.Down), 1) }
            elseif rank == Rank.V3 or Rank == Rank.Rare2 then
                bubble_tiles = { self:get_tile(), self:get_tile(Direction.Up, 1), self:get_tile(Direction.Down, 1) }
            elseif rank == Rank.NM then
                bubble_tiles = { self:get_tile(), self:get_tile(Direction.Up, 1), self:get_tile(Direction.Down, 1),
                    self:get_tile(Direction.join(self:get_facing(), Direction.Up), 1),
                    self:get_tile(Direction.join(self:get_facing(), Direction.Down), 1),
                    self:get_tile(self:get_facing(), 1) }
            end
            rank_relevant_bubbles(self, bubble_tiles)
            Engine.play_audio(BUBBLEIMPACT_SFX, AudioPriority.Highest)
        end
        spell.delete_func = function(self)
            self:erase()
        end
        spell.can_move_to_func = function(tile)
            return true
        end
        field:spawn(spell, start_tile)
    end
end

---Checks if the tile in 2 given directions is free and returns that direction
function get_free_direction(tile, direction1, direction2)
    if (not tile:get_tile(direction1, 1):is_edge()) then
        return direction1
    else return direction2

    end
end

function is_tile_free_for_movement(tile, character)
    --Basic check to see if a tile is suitable for a chracter of a team to move to

    if tile:get_team() ~= character:get_team() or tile:is_reserved({ character:get_id(), character._reserver }) then
        return false
    end
    if (tile:is_edge()) then
        return false
    end
    local occupants = tile:find_entities(function(ent)
        if (Battle.Character.from(ent) ~= nil or Battle.Obstacle.from(ent) ~= nil) then
            return true
        else
            return false
        end
    end)
    if #occupants == 1 and occupants[1]:get_id() == character:get_id() then
        return true
    end
    if #occupants > 0 then
        return false
    end

    return true
end

return package_init
