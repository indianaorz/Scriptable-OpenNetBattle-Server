-- Includes
local battle_helpers = include("battle_helpers.lua")
local zapring = include("ZapRing/entry.lua")

-- Animations and Textures
local CHARACTER_ANIMATION = _folderpath .. "battle.animation"
local CHARACTER_TEXTURE = Engine.load_texture(_folderpath .. "battle.greyscaled.png")
local TELEPORT_TEXTURE = Engine.load_texture(_folderpath .. "teleport.png")
local TELEPORT_ANIM = _folderpath .. "teleport.animation"

--possible states for character
local states = { DEFAULT = 1, SEEK = 2, ATTACK = 3 }
-- Load character resources
---@param self Entity
function package_init(self, character_info)
    -- Required function, main package information
    local base_animation_path = CHARACTER_ANIMATION
    self:set_texture(CHARACTER_TEXTURE)
    self.animation = self:get_animation()
    self.animation:load(base_animation_path)
    -- Load extra resources
    -- Set up character meta
    -- Common Properties
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_height(character_info.height)
    self:set_palette(Engine.load_texture(character_info.palette))
    self.damage = (character_info.damage)
    -- Bunny Specific
    self.fast_hop_frames = (character_info.fast_hop_frames)
    self.frames_between_actions = character_info.frames_between_actions
    self:set_element(Element.Elec)

    --Other Setup
    self:set_explosion_behavior(4, 1, false)
    -- entity will spawn with this animation.
    self.animation:set_state("SPAWN")
    self.frame_counter = 0
    self.started = false
    --This defense rule is added to prevent enemy from gaining invincibility after taking damage.
    self.defense = Battle.DefenseVirusBody.new()
    self:add_defense_rule(self.defense)
    self.move_counter = 0

    -- actions for states

    -- Code that runs in the default state
    ---@param frame number
    self.action_default = function(frame)
        if (frame == self.frames_between_actions) then
            self.move_counter = self.move_counter + 1
            local anim = self:get_animation()
            anim:set_state("WARP_OUT")
            battle_helpers.spawn_visual_artifact(self:get_field(), self:get_tile(), TELEPORT_TEXTURE, TELEPORT_ANIM,
                "MEDIUM_TELEPORT_FROM",
                0, 0)
            anim:on_complete(function()
                battle_helpers.move_random_adjacent(self)
                anim:set_state("WARP_IN")
                anim:on_complete(function()
                    if (self.move_counter < 5) then
                        self.set_state(states.DEFAULT)
                    else
                        self.set_state(states.SEEK)
                        self.move_counter = 0
                    end
                end)
            end)
        end
    end
    --- Code that runs in the seek state
    ---@param frame number
    self.action_seek = function(frame)
        if (frame == self.fast_hop_frames) then
            local target = battle_helpers.find_target(self)
            if (target:get_tile():y() == self:get_tile():y()) or self.move_counter == 8 then
                self.set_state(states.ATTACK)
                return
            end
            self.move_counter = self.move_counter + 1
            local anim = self:get_animation()
            anim:set_state("WARP_OUT")
            battle_helpers.spawn_visual_artifact(self:get_field(), self:get_tile(), TELEPORT_TEXTURE, TELEPORT_ANIM,
                "MEDIUM_TELEPORT_FROM",
                0, 0)
            anim:on_complete(function()
                local moved = battle_helpers.move_towards_row(self, target:get_tile():y())
                anim:set_state("WARP_IN")
                anim:on_complete(function()
                    self.set_state(states.SEEK)
                end)
            end)
        end
    end
    --- Code that runs in the attack state.
    ---@param frame number
    self.action_attack = function(frame)
        if (frame == 1) then
            local props = Battle.CardProperties.new()
            props.damage = self.damage
            props.element = Element.Elec
            zapring.card_create_action(self, props)
        end
    end
    --utility to set the update state, and reset frame counter
    ---@param state number
    self.set_state = function(state)
        self.state = state
        self.frame_counter = 0
    end
    local actions = { [1] = self.action_default, [2] = self.action_seek, [3] = self.action_attack }
    self.update_func = function()
        self.frame_counter = self.frame_counter + 1
        if not self.started then
            self.started = true
            self.set_state(states.DEFAULT)
        else
            local action_func = actions[self.state]
            action_func(self.frame_counter)
        end
    end
end

return package_init
