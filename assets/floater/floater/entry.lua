local enemy_base = include("enemy_base.lua")
local battle_helpers = include("battle_helpers.lua")
local projectile = include("FloaterProjectile/entry.lua")

local CANODUMB_TEXTURE_PATH = _folderpath .. "floater.png"
local CANODUMB_ANIMATION_PATH = _folderpath .. "floater.animation"
local JUMP_SFX_PATH = _folderpath .. "cannon.ogg"
local TELEPORT_TEXTURE = Engine.load_texture(_folderpath .. "teleport.png")
local TELEPORT_ANIM = _folderpath .. "teleport.animation"
local SHADOW_TEXTURE  = Engine.load_texture(_folderpath .. "shadow.png")
local SHADOW_ANIMPATH = _folderpath .. "shadow.animation"

local g_texture = nil
local g_jump_sfx = nil

local function create_shadow(self)
    local node = self:create_node()
    node:set_texture(SHADOW_TEXTURE, true)
    local anim = Engine.Animation.new(SHADOW_ANIMPATH)
    anim:set_state("default")
    anim:set_playback(Playback.Loop)
    anim:refresh(node)
    self:register_component(Battle.Component.new(self, Lifetimes.Battlestep))
    self._shadow_node = node
    
end

function package_init(self, character_info)
    if not g_texture then g_texture = Engine.load_texture(CANODUMB_TEXTURE_PATH) end
    if not g_jump_sfx then g_jump_sfx = Engine.load_audio(JUMP_SFX_PATH) end

    self:set_name("Floater")
    self:set_health(50)
    self:set_height(64)
    self:set_element(Element.None)
    if g_texture then self:set_texture(g_texture) end
    self.animation = self:get_animation()
    self.animation:load(CANODUMB_ANIMATION_PATH)

    self.jump_interval_frames = 20
    self.move_counter = 0
    self.moves_before_attack = 6
    self.should_move = true
    self.move_speed = 10
    self.recovery_speed = 0

    self.defense = Battle.DefenseVirusBody.new()
    self:add_defense_rule(self.defense)

    create_shadow(self)

    local states = {}

    states.IDLE = {
        enter = function(enemy)
            enemy.animation:set_state("Idle")
            enemy.animation:set_playback(Playback.Loop)
        end,
        update = function(enemy, frame)
            if frame >= enemy.jump_interval_frames then
                enemy.frame_counter = 0
                if enemy.should_move then
                    if g_jump_sfx then Engine.play_audio(g_jump_sfx, AudioPriority.Low) end
                    battle_helpers.spawn_visual_artifact(enemy:get_field(), enemy:get_tile(), TELEPORT_TEXTURE, TELEPORT_ANIM,
                        "MEDIUM_TELEPORT_FROM", 0, 0)
                    if battle_helpers.move_random_adjacent(enemy) then
                        enemy.move_counter = enemy.move_counter + 1
                        if enemy.move_counter >= enemy.moves_before_attack then
                            enemy:set_state("START_ATTACK")
                        end
                    end
                end
            end
        end
    }

    states.START_ATTACK = {
        enter = function(enemy)
            local anim = enemy.animation
            anim:set_state("ShootStart")
            anim:set_playback(Playback.Once)
            enemy.should_move = false
            anim:on_complete(function()
                projectile.create(enemy, 10)
                enemy:set_state("END_ATTACK")
            end)
        end
    }

    states.END_ATTACK = {
        enter = function(enemy)
            local anim = enemy.animation
            anim:set_state("ShootEnd")
            anim:set_playback(Playback.Once)
            anim:on_complete(function()
                enemy.should_move = true
                enemy.move_counter = 0
                enemy:set_state("IDLE")
            end)
        end
    }

    self.delete_func = function(enemy)
        if enemy._shadow_node then
            enemy._shadow_node:hide()
        end
    end

    enemy_base.init(self, {states = states, start_state = "IDLE"})
end

return package_init
