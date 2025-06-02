-- Includes
---@type BattleHelper
local battle_helpers = include("battle_helpers.lua")
---@type Blade
local boomerang = include("boomerang.lua")
-- Animations and Textures
local CHARACTER_ANIMATION = _folderpath .. "battle.animation"
local CHARACTER_TEXTURE = Engine.load_texture(_folderpath .. "battle.greyscaled.png")
local SLASH = Engine.load_texture(_folderpath .. "QuickBlade.png")
local SLASH_ANIM = _folderpath .. "QuickBlade.animation"
local slash = Engine.load_audio(_folderpath .. "slash.ogg")

local AUDIO_DAMAGE = Engine.load_audio(_folderpath .. "hitsound.ogg")

--possible states for character
local states = { DEFAULT = 1, MOVE = 2, BMRNG = 3, SWORD = 4, }
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
    self.max_hp = character_info.hp
    self:set_height(character_info.height)
    self.damage = (character_info.damage)
    self.sword_damage = character_info.sword_damage
    self:set_palette(Engine.load_texture(character_info.palette))
    -- Quickman Specific
    self:set_element(character_info.element)
    self.max_boomerangs = character_info.max_boomerangs;
    self.boomerangs = self.max_boomerangs;

    --Other Setup
    self:set_explosion_behavior(4, 1, false)
    -- entity will spawn with this animation.
    self.animation:set_state("IDLE")
    self.animation:set_playback(Playback.Loop)
    self.frame_counter = 0
    self.started = false
    self.move_counter = 0

    self.can_move_to_func = function(tile)
        if (self.state == states.SWORD) then
            return true
        else
            local canMove = battle_helpers.can_move_to_func(tile, self)
            return canMove
        end
    end


    self:register_status_callback(Hit.Flinch, function()
        local anim = self:get_animation()
        if (self.state == states.SWORD) then
            battle_helpers.move_at_random(self)
        end
        if (self.state == states.NM) then
            self.frame_counter = -5
        else
            self.set_state(states.DEFAULT)
            anim:set_state("PLAYER_HIT")
            self.frame_counter = -10
        end
    end)

    self.defense_rule = Battle.DefenseRule.new(0, DefenseOrder.Always)
    local defense_texture = Engine.load_texture(_folderpath .. "guard_hit.png")
    local defense_animation = _folderpath .. "guard_hit.animation"
    local defense_audio = Engine.load_audio(_folderpath .. "tink.ogg")
    self.defense_rule.can_block_func = function(judge, attacker, defender)
        local attacker_hit_props = attacker:copy_hit_props()

        if (self.state == nil or self.state == states.DEFAULT) then

            if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
                --cant block breaking hits
                return false
            end
            judge:block_impact()
            judge:block_damage()
            local artifact = Battle.Spell.new(self:get_team())
            artifact:set_texture(defense_texture)
            artifact:set_offset(0, -50)
            local anim = artifact:get_animation()
            anim:load(defense_animation)
            anim:set_state("DEFAULT")
            anim:refresh(artifact:sprite())
            anim:on_complete(function()
                artifact:erase()
            end)
            self.animation:set_state("BLOCK")
            self.animation:on_complete(function()
                self.animation:set_state("IDLE")
                self.animation:set_playback(Playback.Loop)
            end)
            self:get_field():spawn(artifact, self:get_tile())
            Engine.play_audio(defense_audio, AudioPriority.High)
        end
    end
    self:add_defense_rule(self.defense_rule)


    -- actions for states

    -- Code that runs in the default state
    ---@param frame number
    self.action_default = function(frame)
        if (frame == 1) then
            self.animation:set_state("IDLE")
            self.animation:set_playback(Playback.Loop)
            self.boomerangs = self.max_boomerangs;
        end
        if (self:get_rank() == Rank.NM and frame % 30 == 0) then
            self.move_rand()
        end
        if (frame == 120) then
            self.set_state(states.MOVE)
        end
    end

    self.move_rand = function()
        self.animation:set_state("TELEPORT_IN")
        self.animation:on_complete(function()
            battle_helpers.move_at_random(self)
            self.animation:set_state("TELEPORT_OUT")
        end)
    end

    self.action_move = function(frame)
        if (frame == 1) then
            self.animation:set_state("TELEPORT_IN")
            self.animation:on_complete(function()
                battle_helpers.move_at_random(self)
                self.animation:set_state("TELEPORT_OUT")
            end)
        end
        if (frame == 10) then
            self.move_counter = self.move_counter + 1
            if (self.move_counter > 8) then
                self.set_state(states.BMRNG)
                self.move_counter = 0
            else
                self.set_state(states.MOVE)
            end
        end
    end

    --- Code that runs in the attack state.
    ---@param frame number
    self.action_attack = function(frame)
        if (frame == 1) then
            self.animation:set_state("TELEPORT_IN")
            self.animation:on_complete(function()
                battle_helpers.move_at_random_avoid_same_row(self)
                self.animation:set_state("TELEPORT_OUT")
            end)
        end
        if (frame == 10) then
            boomerang.throw(self, self.damage)
            self.boomerangs = self.boomerangs - 1;
        end
    end

    --- Code that runs in the attack state.
    ---@param frame number
    self.action_sword = function(frame)
        if (frame == 1) then
            self.animation:set_state("TELEPORT_IN")
            self.animation:on_complete(function()
                local targetChar = battle_helpers.find_target(self)
                local moved = battle_helpers.move_in_front_of_enemy(self, targetChar)
                self.animation:set_state("TELEPORT_OUT")
            end)
        end
        if (frame == 10) then
            self.animation:set_state("SLASH")
            self.animation:on_frame(7, function()
                self:toggle_counter(true)
            end)
            self.animation:on_frame(9, function()
                self:toggle_counter(false)
                create_slash(self, self:get_field())
            end)
        elseif (frame == 50) then
            self.animation:set_state("TELEPORT_IN")
            self.animation:on_complete(function()
                battle_helpers.move_at_random(self)
                self.set_state(states.DEFAULT)
                self.animation:set_state("TELEPORT_OUT")
            end)
        end
    end
    --utility to set the update state, and reset frame counter
    ---@param state number
    self.set_state = function(state)
        self.state = state
        self.frame_counter = 0
    end
    local actions = { [1] = self.action_default, [2] = self.action_move, [3] = self.action_attack,
        [4] = self.action_sword }
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

function spawn_wide_hitbox(field, spell, desired_tile)
    local hitbox = Battle.Spell.new(spell:get_team())
    hitbox:set_hit_props(spell:copy_hit_props())
    field:spawn(hitbox, desired_tile)
    return hitbox
end

function create_slash(user, field)
    Engine.play_audio(slash, AudioPriority.Highest)
    local spell = Battle.Spell.new(user:get_team())
    local direction = user:get_facing()

    local spell_animation = spell:get_animation()
    spell.frames = 0
    spell:set_facing(direction)
    spell:set_hit_props(
        HitProps.new(
            user.sword_damage,
            Hit.Impact | Hit.Flash | Hit.Flinch,
            Element.Sword,
            user:get_id(),
            Drag.None
        )
    )
    spell:set_facing(user:get_facing())
    spell_animation:load(SLASH_ANIM)
    spell_animation:set_state("0")
    spell:set_texture(SLASH)
    spell_animation:refresh(spell:sprite())
    spell:sprite():set_layer(-2)
    spell_animation:on_complete(function()
        spell:erase()
    end)
    local origin_tile = user:get_tile(user:get_facing(), 1)
    field:spawn(spell, origin_tile)
    local hitbox1 = spawn_wide_hitbox(field, spell, origin_tile:get_tile(Direction.Up, 1))
    local hitbox2 = spawn_wide_hitbox(field, spell, origin_tile:get_tile(Direction.Down, 1))

    spell.update_func = function(self, dt)
        spell.frames = spell.frames + 1
        self:get_current_tile():attack_entities(self)
        hitbox1:get_current_tile():attack_entities(hitbox1)
        hitbox2:get_current_tile():attack_entities(hitbox2)
        if (spell.frames > 60) then
            spell:erase()



        end
    end



    spell.collision_func = function(self, other)
    end

    spell.can_move_to_func = function(self, other)
        return true
    end

    spell.battle_end_func = function(self)
        spell:erase()
    end

    spell.attack_func = function()
        Engine.play_audio(AUDIO_DAMAGE, AudioPriority.High)
    end


end

function Tiletostring(tile)
    return "Tile: [" .. tostring(tile:x()) .. "," .. tostring(tile:y()) .. "]"
end

return package_init
