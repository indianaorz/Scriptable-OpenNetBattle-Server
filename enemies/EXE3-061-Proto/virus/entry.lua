local print_debug = false

local AUDIO_DAMAGE_PLAYER = Engine.load_audio(_modpath.."sfx/EXE3_185.ogg", true)
local AUDIO_DAMAGE_ENEMY = Engine.load_audio(_modpath.."sfx/EXE3_118.ogg", true)

local EFFECT_TEXTURE = Engine.load_texture(_modpath.."gfx/effect.png")
local EFFECT_ANIMPATH = _modpath.."gfx/effect.animation"
local GUARD_HIT_TEXTURE = Engine.load_texture(_modpath.."gfx/guard_hit.png")
local GUARD_HIT_ANIMPATH = _modpath.."gfx/guard_hit.animation"
local BOOM_TEXTURE = Engine.load_texture(_modpath.."gfx/boom.png")
local BOOM_ANIMPATH = _modpath.."gfx/boom.animation"
local MOB_MOVE_TEXTURE = Engine.load_texture(_modpath.."gfx/mob_move.png")
local MOB_MOVE_ANIMPATH = _modpath.."gfx/mob_move.animation"
local FLASH_TEXTURE = Engine.load_texture(_modpath.."gfx/flash.png")
local FLASH_ANIMPATH = _modpath.."gfx/flash.animation"

local GUARD_HIT_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_14.ogg", true)
local CRACK_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_208.ogg", true)

local PROTO_POOL_TEXTURE = Engine.load_texture(_modpath.."gfx/proto_pool.png")
local PROTO_POOL_ANIMPATH = _modpath.."gfx/proto_pool.animation"
local PROTO_ARM_UPPER_TEXTURE = Engine.load_texture(_modpath.."gfx/arm_upper.png")
local PROTO_ARM_UPPER_ANIMPATH = _modpath.."gfx/arm_upper.animation"
local PROTO_ARM_LOWER_TEXTURE = Engine.load_texture(_modpath.."gfx/arm_lower.png")
local PROTO_ARM_LOWER_ANIMPATH = _modpath.."gfx/arm_lower.animation"
local PROTO_CORE_TEXTURE = Engine.load_texture(_modpath.."gfx/proto_core.png")
local PROTO_CORE_ANIMPATH = _modpath.."gfx/proto_core.animation"

local REVERSEVULCAN_SHOOT_TEXTURE = Engine.load_texture(_modpath.."gfx/vulcan_fx.png")
local REVERSEVULCAN_SHOOT_ANIMPATH = _modpath.."gfx/vulcan_fx.animation"
local REDEYESDELETE_LASER_TEXTURE = Engine.load_texture(_modpath.."gfx/red_eyes_delete.png")
local REDEYESDELETE_LASER_ANIMPATH = _modpath.."gfx/red_eyes_delete.animation"
local REDEYESDELETE_PROJECTILE_TEXTURE = Engine.load_texture(_modpath.."gfx/red_eyes_delete_projectile.png")
local REDEYESDELETE_PROJECTILE_ANIMPATH = _modpath.."gfx/red_eyes_delete_projectile.animation"
local PROTOARM_SIGMA_TEXTURE = Engine.load_texture(_modpath.."gfx/protoarm_sigma.png")
local PROTOARM_SIGMA_ANIMPATH = _modpath.."gfx/protoarm_sigma.animation"
local PROTOARM_OMEGA_TEXTURE = Engine.load_texture(_modpath.."gfx/protoarm_omega.png")
local PROTOARM_OMEGA_ANIMPATH = _modpath.."gfx/protoarm_omega.animation"

local STONECUBE_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_23.ogg", true)
local DEVILHAND_AUDIO_1 = Engine.load_audio(_modpath.."sfx/EXE3_88.ogg", true)
local DEVILHAND_AUDIO_2 = Engine.load_audio(_modpath.."sfx/EXE3_124.ogg", true)
local REVERSEVULCAN_SPAWN_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_13.ogg", true)
local REVERSEVULCAN_SHOOT_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_64.ogg", true)
local REDEYESDELETE_CHARGE_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_181.ogg", true)
local REDEYESDELETE_SHOOT_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_188.ogg", true)
local PROTOARM_SIGMA_AUDIO_1 = Engine.load_audio(_modpath.."sfx/EXE3_198.ogg", true)
local PROTOARM_SIGMA_AUDIO_2 = Engine.load_audio(_modpath.."sfx/EXE3_148.ogg", true)
local PROTOARM_OMEGA_DASH_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_96.ogg", true)
local PROTOARM_OMEGA_BOOM_AUDIO = Engine.load_audio(_modpath.."sfx/EXE3_161.ogg", true)

local ObstacleInfo = include("ObstacleInfo.lua")

function debug_print(text)
    if print_debug then
        print("[Proto] "..text)
    end
end

local query = function(o, user)
    return Battle.Obstacle.from(o) ~= nil and o:get_health() > 0
end

local function create_mob_move(state)
    local artifact = Battle.Artifact.new()
    artifact:set_facing(Direction.Right)
    artifact:set_texture(MOB_MOVE_TEXTURE)
    artifact:sprite():set_layer(-99)
    local anim = artifact:get_animation()
    anim:load(MOB_MOVE_ANIMPATH)
    anim:set_state(state) --Set the state
    anim:refresh(artifact:sprite())
    anim:on_complete(function()
        artifact:erase() --Delete the artifact when the animation completes
    end)
    return artifact
end

local function end_proto_arm(proto)
    if proto.proto_arm_type[proto.proto_arm_index] == "OMEGA" then
        proto.cooldown = 120
    else
        proto.cooldown = 60
    end
    proto.is_acting = false
    proto.goop_health = 40
    proto.anim_once = true
    proto.sigma_index = 1
    proto.omega_attack = false
    proto.is_vulnerable = false
    proto.pattern_index = proto.pattern_index + 1
    debug_print("pattern_index: "..proto.pattern_index)
    if proto.pattern_index > #proto.pattern then
        debug_print("reset to 1")
        proto.pattern_index = 1
        proto.pattern = {"DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "CHOOSE ATTACK"}
    end
    proto.proto_arm_index = math.random(1,2)
    local field = proto:get_field()
    local mob_move1 = create_mob_move("5")
    field:spawn(mob_move1, proto.upper_arm:get_tile())
    local mob_move2 = create_mob_move("5")
    field:spawn(mob_move2, proto.lower_arm:get_tile())
    proto.upper_arm:reveal()
    proto.lower_arm:reveal()
    proto.upper_arm:toggle_hitbox(true)
    proto.lower_arm:toggle_hitbox(true)
end

local function choose_attack(proto)
    if proto:get_health() < math.floor(proto.health/2) then
        if proto.set_new_pattern then
            proto.set_new_pattern = false
            if proto:get_rank() == Rank.SP then
                proto.attack_index = math.random(1,4)
            else
                proto.attack_index = 1
            end
        end
    else
        if not proto.set_new_pattern then
            proto.set_new_pattern = true
            proto.attack_index = 1
        end
    end
    debug_print("attack_index: "..proto.attack_index)
    if proto:get_rank() == Rank.SP then
        debug_print("SP rank")
        if proto:get_health() < math.floor(proto.health/2) then
            debug_print("HP < /2")
            if proto.attack_index == 2 then
                table.insert(proto.pattern, proto.attack_reversevulcan)
            elseif proto.attack_index == 3 then
                table.insert(proto.pattern, proto.attack_redeyesdelete)
            elseif proto.attack_index == 4 then
                table.insert(proto.pattern, proto.attack_protoarm)
            else
                table.insert(proto.pattern, proto.attack_godhand)
                table.insert(proto.pattern, proto.attack_godhand)
            end
        else
            debug_print("HP >= /2")
            if proto.attack_index == 2 then
                table.insert(proto.pattern, proto.attack_redeyesdelete)
            elseif proto.attack_index == 3 then
                table.insert(proto.pattern, proto.attack_godhand)
                table.insert(proto.pattern, proto.attack_godhand)
            else
                table.insert(proto.pattern, proto.attack_reversevulcan)
            end
        end
    else
        debug_print("not SP rank")
        if proto:get_health() < math.floor(proto.health/2) then
            debug_print("HP < /2")
            if proto.attack_index == 2 then
                table.insert(proto.pattern, proto.attack_protoarm)
            else
                table.insert(proto.pattern, proto.attack_redeyesdelete)
            end
        else
            debug_print("HP >= /2")
            if proto.attack_index == 2 then
                table.insert(proto.pattern, proto.attack_redeyesdelete)
            else
                table.insert(proto.pattern, proto.attack_reversevulcan)
            end
        end
    end
    if proto:get_rank() == Rank.SP then
        if proto:get_health() < math.floor(proto.health/2) then
            proto.attack_index = math.random(1,4)
            debug_print("next attack_index: "..proto.attack_index)
            if proto.attack_index > 4 then
                debug_print("MORE THAN 4! reset to 1")
                proto.attack_index = 1
            end
        else
            proto.attack_index = proto.attack_index + 1
            debug_print("next attack_index: "..proto.attack_index)
            if proto.attack_index > 3 then
                debug_print("MORE THAN 3! reset to 1")
                proto.attack_index = 1
            end
        end
    else
        proto.attack_index = proto.attack_index + 1
        debug_print("next attack_index: "..proto.attack_index)
        if proto.attack_index > 2 then
            debug_print("MORE THAN 2! reset to 1")
            proto.attack_index = 1
        end
    end
    proto.pattern_index = proto.pattern_index + 1
end

local function drop_trace_fx(target_artifact, desired_color, color_mode1, color_mode2)
    --drop an afterimage artifact mimicking the appearance of an existing spell/artifact/character and blinking for a couple frames before disappearing
    local fx = Battle.Artifact.new()
    local anim = target_artifact:get_animation()
    local field = target_artifact:get_field()
    local offset = target_artifact:get_offset()
    local texture = target_artifact:get_texture()
    local elevation = target_artifact:get_elevation()
    fx:set_facing(target_artifact:get_facing())
    fx:set_texture(texture, true)
    fx:get_animation():copy_from(anim)
    fx:get_animation():set_state(anim:get_state())
    fx:set_offset(offset.x,offset.y)
    fx:set_elevation(elevation)
    fx:get_animation():refresh(fx:sprite())
    fx.frame_timer = 0
    fx.update_func = function(self, dt)
        self.frame_timer = self.frame_timer + 1
        local alpha = nil
        if (self.frame_timer % 2 == 0) then
            alpha = 0
            self:sprite():set_color_mode(color_mode1)
        else
            alpha = 255
            self:sprite():set_color_mode(color_mode2)
        end
        self:set_color(Color.new(desired_color[1], desired_color[2], desired_color[3], alpha))
        if self.frame_timer >= 10 then
            self:erase()
        end
    end

    local tile = target_artifact:get_tile()
    field:spawn(fx, tile)
    return fx
end

local function create_claw_defense()
    local defense = Battle.DefenseRule.new(2, DefenseOrder.Always)
    defense.can_block_func = function(judge, attacker, defender)
        local attacker_hit_props = attacker:copy_hit_props()
        judge:block_damage()
        judge:block_impact()
        if attacker_hit_props.damage > 0 then
            create_effect(Direction.Right, GUARD_HIT_TEXTURE, GUARD_HIT_ANIMPATH, "0", (math.random(-6,5)*2), (math.random(-7,4)*2), -999, defender:get_field(), defender:get_tile())
            Engine.play_audio(GUARD_HIT_AUDIO, AudioPriority.Low)
        end
    end
    return defense
end

local function find_best_target(proto)
    --local facing = proto:get_facing()
    local target = proto:get_target()
    local field = proto:get_field()
    local query = function(c)
        return c:get_team() ~= proto:get_team()
    end
    local potential_threats = field:find_characters(query)
    local goal_hp = 0
    if #potential_threats > 0 then
        for i = 1, #potential_threats, 1 do
            local possible_target = potential_threats[i]
            if possible_target and not possible_target:is_deleted() and possible_target:get_health() >= goal_hp then
                target = possible_target
            end
        end
    end
    return target
end

local function create_red_eye_arrow(proto, props, state, direction)
    local spell = Battle.Spell.new(proto:get_team())
    spell:set_hit_props(props)
    spell:set_texture(REDEYESDELETE_PROJECTILE_TEXTURE)
    spell:set_facing(proto:get_facing())
    local anim = spell:get_animation()
    anim:load(REDEYESDELETE_PROJECTILE_ANIMPATH)
    anim:set_state(state)
    spell:sprite():set_layer(-3) --set_layer determines the order sprites visually draw in.
    anim:refresh(spell:sprite())
    spell.slide_started = false
    spell.update_func = function(self, dt)
        if self:is_deleted() then return end
        local tile = self:get_tile()
        if tile:is_edge() and self.slide_started then self:delete() end
        tile:attack_entities(self)
        local dest = self:get_tile(direction, 1)
        local ref = self
        if dest and #dest:find_entities(query) > 0 then self:delete() end
        self:slide(dest, frames(7), frames(0), ActionOrder.Voluntary, function()
            ref.slide_started = true
            tile:attack_entities(self)
        end)
    end
    spell.attack_func = function(self, ent)
        if Battle.Obstacle.from(ent) == nil then
            --[[
			if Battle.Player.from(proto) ~= nil then
				Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
			end
            ]]
		else
			Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
		end
    end
    spell.can_move_to_func = function(tile)
        return true
    end
    return spell
end

local function create_sigma_taser(proto)
    local spell = Battle.Spell.new(proto:get_team())
    spell:set_texture(PROTOARM_SIGMA_TEXTURE)
    spell:set_facing(proto:get_facing())
    spell:sprite():set_layer(-4)
    local damage = 60
    if proto:get_rank() == Rank.SP then damage = 200 end
    spell:set_hit_props(
        HitProps.new(
            damage,
            Hit.Impact | Hit.Flinch | Hit.Flash,
            Element.None,
            proto:get_context(),
            Drag.None
        )
    )
    local anim = spell:get_animation()
    anim:load(PROTOARM_SIGMA_ANIMPATH)
    anim:set_state(proto.sigma_state[proto.sigma_index])
    anim:refresh(spell:sprite())
    if anim:get_state() == "SINGLE ROW" then
        Engine.play_audio(PROTOARM_SIGMA_AUDIO_1, AudioPriority.Low)
    else
        Engine.play_audio(PROTOARM_SIGMA_AUDIO_2, AudioPriority.Low)
    end
    anim:on_complete(function()
        proto.sigma_index = proto.sigma_index + 1
        proto.sigma_count = proto.sigma_count + 1
        if proto.sigma_index > #proto.sigma_state then proto.sigma_index = 1 end
        anim:set_state(proto.sigma_state[proto.sigma_index])
        anim:refresh(spell:sprite())
        spell.anim_once = true
    end)
    local field = proto:get_field()
    local facing = proto:get_facing()
    local center_tile = proto:get_tile(facing, 2)
    local upper_tile = center_tile:get_tile(Direction.Up, 1)
    local lower_tile = center_tile:get_tile(Direction.Down, 1)
    local center_table = {center_tile}
    local up_down_table = {center_tile}
    for x = 0, 6, 1 do
        local prospective_addition = upper_tile:get_tile(facing, x)
        if prospective_addition and not prospective_addition:is_edge() then table.insert(up_down_table, prospective_addition) end
        prospective_addition = lower_tile:get_tile(facing, x)
        if prospective_addition and not prospective_addition:is_edge() then table.insert(up_down_table, prospective_addition) end
        prospective_addition = center_tile:get_tile(facing, x)
        if prospective_addition and not prospective_addition:is_edge() then table.insert(center_table, prospective_addition) end
    end
    local tile_array = {center_table, up_down_table}
    spell.on_spawn_func = function(self)
        for i = 1, #tile_array[proto.sigma_index], 1 do
            local check_tile = tile_array[proto.sigma_index][i]
            if check_tile and not check_tile:is_edge() then
                local hitbox = Battle.Spell.new(self:get_team())
                hitbox:set_hit_props(self:copy_hit_props())
                hitbox.update_func = function(self, dt)
                    self:get_tile():attack_entities(self)
                    self:erase()
                end
                hitbox.attack_func = function(self, other)
                    create_effect(Direction.Right, EFFECT_TEXTURE, EFFECT_ANIMPATH, "8", (math.random(-6,5)*2), (math.random(-7,4)*2), -999, other:get_field(), other:get_tile())
                    if Battle.Obstacle.from(other) == nil then
                        --[[
                        if Battle.Player.from(proto) ~= nil then
                            Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
                        end
                        ]]
                    else
                        Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
                    end
                end
                field:spawn(hitbox, check_tile)
            end
        end
    end
    spell.can_move_to_func = function(tile) return true end
    spell.anim_once = false
    spell.update_func = function(self, dt)
        if self.anim_once then
            self.anim_once = false
            if anim:get_state() == "SINGLE ROW" then
                Engine.play_audio(PROTOARM_SIGMA_AUDIO_1, AudioPriority.Low)
            else
                Engine.play_audio(PROTOARM_SIGMA_AUDIO_2, AudioPriority.Low)
            end
            for i = 1, #tile_array[proto.sigma_index], 1 do
                local hitbox = Battle.Spell.new(self:get_team())
                hitbox:set_hit_props(self:copy_hit_props())
                hitbox.update_func = function(self)
                    self:get_tile():attack_entities(self)
                    self:erase()
                end
                hitbox.attack_func = function(self, other)
                    create_effect(Direction.Right, EFFECT_TEXTURE, EFFECT_ANIMPATH, "8", (math.random(-6,5)*2), (math.random(-7,4)*2), -999, other:get_field(), other:get_tile())
                end
                field:spawn(hitbox, tile_array[proto.sigma_index][i])
            end
            anim:on_complete(function()
                proto.sigma_count = proto.sigma_count + 1
                if proto.sigma_count >= 16 then
                    proto.is_acting = false
                    self:erase()
                else
                    proto.sigma_index = proto.sigma_index + 1
                    if proto.sigma_index > #proto.sigma_state then proto.sigma_index = 1 end
                    anim:set_state(proto.sigma_state[proto.sigma_index])
                    anim:refresh(spell:sprite())
                    spell.anim_once = true
                end
            end)
        end
    end
    return spell
end

local function create_omega_rocket(proto)
    --local spell = Battle.Spell.new(proto:get_team())
    local spell = Battle.Obstacle.new(proto:get_team())
    ObstacleInfo.set_cannot_be_manipulated(spell, true)
    spell:toggle_hitbox(true)
    spell:set_texture(PROTOARM_OMEGA_TEXTURE)
    spell:set_facing(proto:get_facing())
    spell:sprite():set_layer(-4)
    spell:set_health(500)
    local damage = 100
    if proto:get_rank() == Rank.SP then damage = 300 end
    local props = HitProps.new(
        damage,
        Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking,
        Element.None,
        proto:get_context(),
        Drag.None
    )
    spell:set_hit_props(props)
    local anim = spell:get_animation()
    anim:load(PROTOARM_OMEGA_ANIMPATH)
    anim:set_state("IDLE")
    anim:refresh(spell:sprite())
    anim:on_complete(function()
        anim:set_state("TAKEOFF")
        anim:refresh(spell:sprite())
    end)
    spell.flight = false
    spell.slide_started = false
    spell.has_exploded = false
    spell.can_move_to_func = function(tile) return true end
    local field = proto:get_field()
    local function run_explosion(hitter, array1, array2)
        Engine.play_audio(PROTOARM_OMEGA_BOOM_AUDIO, AudioPriority.Low)
        local flashlight = Battle.Spell.new(spell:get_team())
        flashlight:set_facing(Direction.Right)
        local flashlight_anim = flashlight:get_animation()
        flashlight:set_texture(FLASH_TEXTURE, true)
        flashlight:sprite():set_layer(10)
        flashlight_anim:load(FLASH_ANIMPATH)
        flashlight_anim:set_state("0")
        flashlight_anim:refresh(flashlight:sprite())
        flashlight_anim:on_frame(2, function()
            for i = 1, #array1, 1 do
                local boom = Battle.Artifact.new()
                boom:set_texture(BOOM_TEXTURE)
                boom:sprite():set_layer(-99)
                local anim2 = boom:get_animation()
                anim2:load(BOOM_ANIMPATH)
                anim2:set_state("0")
                anim2:refresh(boom:sprite())
                anim2:on_complete(function()
                    boom:erase()
                end)
                field:spawn(boom, array1[i])
                local hitbox = Battle.Spell.new(proto:get_team())
                hitbox:set_hit_props(props)
                hitbox.update_func = function(self)
                    self:get_tile():attack_entities(self)
                    self:erase()
                end
                field:spawn(hitbox, array1[i])
            end
        end)
        flashlight_anim:on_frame(3, function()
            for i = 1, #array2, 1 do
                local boom = Battle.Artifact.new()
                boom:set_texture(BOOM_TEXTURE)
                boom:sprite():set_layer(-99)
                local anim2 = boom:get_animation()
                anim2:load(BOOM_ANIMPATH)
                anim2:set_state("0")
                anim2:refresh(boom:sprite())
                anim2:on_complete(function()
                    boom:erase()
                end)
                field:spawn(boom, array2[i])
                local hitbox = Battle.Spell.new(proto:get_team())
                hitbox:set_hit_props(props)
                hitbox.update_func = function(self)
                    self:get_tile():attack_entities(self)
                    self:erase()
                end
                field:spawn(hitbox, array2[i])
            end
        end)
        flashlight_anim:on_complete(function()
            flashlight:erase()
        end)
        field:spawn(flashlight, 1, 1)
        --hitter:shake_camera(15, frames(60))
        hitter:shake_camera(15, 0.783)
    end
    spell.collision_func = function(self, other)
    end
    spell.back_boom_array1 = {field:tile_at(1, 1), field:tile_at(1, 2), field:tile_at(1, 3)}
    spell.back_boom_array2 = {field:tile_at(2, 1), field:tile_at(2, 2), field:tile_at(2, 3)}
    local direction = spell:get_facing()
    local play_sound = true
    spell.update_func = function(self, dt)
        if self:is_deleted() then return end
        if anim:get_state() == "TAKEOFF" then
            anim:on_complete(function()
                anim:set_state("FLIGHT")
                anim:refresh(spell:sprite())
            end)
        elseif anim:get_state() == "FLIGHT" then
            if play_sound then
                play_sound = false
                Engine.play_audio(PROTOARM_OMEGA_DASH_AUDIO, AudioPriority.Low)
            end
            local tile = self:get_tile()
            local dest = self:get_tile(direction, 1)
            tile:attack_entities(self)
            if dest and not dest:is_edge() then
                dest:attack_entities(self)
            end
            if not self:is_sliding() then
                if tile:is_edge() and self.slide_started then
                    self.has_exploded = true
                    self:delete()
                end
                local ref = self
                self:slide(dest, frames(8), frames(0), ActionOrder.Voluntary, function()
                    ref.slide_started = true
                end)
            end
        end
    end
    spell.delete_func = function(self)
        if self.has_exploded then
            run_explosion(self, self.back_boom_array1, self.back_boom_array2)
            self.has_exploded = false
            proto.is_acting = false
            self:erase()
        end
    end
    return spell
end

local function take_proto_arm_action(proto, current_arm)
    proto.is_acting = true
    proto.is_vulnerable = false
    local field = proto:get_field()
    if current_arm == "SIGMA" then
        local spell = create_sigma_taser(proto)
        field:spawn(spell, proto:get_tile(proto:get_facing(), 2))
        return spell
    elseif current_arm == "OMEGA" then
        local spell = create_omega_rocket(proto)
        field:spawn(spell, proto:get_tile(proto:get_facing(), 1))
        return spell
    else
        proto.is_acting = false
    end
end

local function take_red_eye_action(proto, state)
    proto.is_acting = true --Set to acting so we don't spam lasers.
    local field = proto:get_field()
    local first_tile = proto:get_tile(proto:get_facing(), 2)
    local tile_array = {first_tile, first_tile:get_tile(Direction.Up, 1), first_tile:get_tile(proto:get_facing(), 1), first_tile:get_tile(Direction.Down, 1)}
    local artifact = Battle.Spell.new(proto:get_team())
    artifact:set_texture(REDEYESDELETE_LASER_TEXTURE)
    artifact:sprite():set_layer(-4)
    local anim = artifact:get_animation()
    anim:load(REDEYESDELETE_LASER_ANIMPATH)
    anim:set_state(state) --Set the state
    anim:refresh(artifact:sprite())
    local damage = 80
    if proto:get_rank() == Rank.SP then damage = 200 end
    local props1 = HitProps.new(
        damage,
        Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking,
        Element.None,
        proto:get_context(),
        Drag.None
    )
    local props2 = HitProps.new(
        damage,
        Hit.Impact | Hit.Flinch | Hit.Flash,
        Element.None,
        proto:get_context(),
        Drag.None
    )
    anim:on_complete(function()
        local state = anim:get_state()
        if state == "ATTACK_CHARGE" then
            anim:set_state("ATTACK_FIRE")
            Engine.play_audio(REDEYESDELETE_SHOOT_AUDIO, AudioPriority.Low)
            anim:on_complete(function()
                anim:set_state("ATTACK_LAND")
                local hitbox = Battle.Spell.new(proto:get_team())
                hitbox:set_hit_props(props1)
                hitbox.update_func = function(self)
                    self:get_tile():attack_entities(self)
                    self:erase()
                end
                field:spawn(hitbox, tile_array[1])
                anim:on_complete(function()
                    anim:set_state("ATTACK_DISSIPATE")
                    anim:on_complete(function()
                        artifact:delete()
                        proto.is_acting = false
                        proto.cooldown = 40
                    end)
                end)
                --If the landing tile of Red Eyes Delete isn't broken, Crack/Break the tiles.
                --Do this by scanning the compiled tiles above for Cracked state and breaking them if Cracked.
                --If NOT Cracked, then Crack them.
                if tile_array[1]:get_state() ~= TileState.Broken then
                    Engine.play_audio(CRACK_AUDIO, AudioPriority.Low)
                    --proto:shake_camera(8, frames(60))
                    proto.shake_component.timer = 20
                    for i = 1, #tile_array, 1 do
                        if tile_array[i]:get_state() == TileState.Cracked then
                            tile_array[i]:set_state(TileState.Broken)
                        else
                            tile_array[i]:set_state(TileState.Cracked)
                        end
                    end
                    local up = create_red_eye_arrow(proto, props2, "UP", Direction.Up)
                    local forward = create_red_eye_arrow(proto, props2, "FORWARD", proto:get_facing())
                    local down = create_red_eye_arrow(proto, props2, "DOWN", Direction.Down)
                    local check_up = tile_array[2]
                    if check_up and not check_up:is_edge() then
                        field:spawn(up, check_up)
                    end
                    field:spawn(forward, tile_array[3])
                    local check_down = tile_array[4]
                    if check_down and not check_down:is_edge() then
                        field:spawn(down, check_down)
                    end
                end
            end)
        end
    end)
    Engine.play_audio(REDEYESDELETE_CHARGE_AUDIO, AudioPriority.Low)
    field:spawn(artifact, proto:get_tile())
end

local function create_reverse_vulcan_shot(proto, props)
    local shot = Battle.Spell.new(proto:get_team())
    shot:highlight_tile(Highlight.Solid)
    shot:set_hit_props(props)
    shot:set_facing(proto:get_facing())
    shot:sprite():set_layer(-4)
    shot:set_texture(REVERSEVULCAN_SHOOT_TEXTURE)
    local anim = shot:get_animation()
    anim:load(REVERSEVULCAN_SHOOT_ANIMPATH)
    anim:set_state("TILE_BURST")
    anim:refresh(shot:sprite())
    anim:on_complete(function()
        proto.vulcan_shots = proto.vulcan_shots + 1
        proto.is_acting = false
    end)
    shot.delay = 15
    shot.update_func = function(self, dt)
        if self.delay <= 0 then
            local tile = self:get_tile()
            if tile:is_walkable() then
                tile:attack_entities(self)
            end
            self:erase()
        else
            self.delay = self.delay - 1
        end
    end
    shot.attack_func = function(self, other)
        if Battle.Obstacle.from(other) == nil then
            --[[
			if Battle.Player.from(proto) ~= nil then
				Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
			end
            ]]
		else
			Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
		end
    end
    shot.can_move_to_func = function(tile)
        return true
    end
    return shot
end

local function create_reverse_vulcan_flare(proto)
    local artifact = Battle.Spell.new(Team.Blue)
    artifact:set_texture(REVERSEVULCAN_SHOOT_TEXTURE)
    artifact:sprite():set_layer(-4)
    local anim2 = artifact:get_animation()
    anim2:load(REVERSEVULCAN_SHOOT_ANIMPATH)
    anim2:set_state("CANNON_BURST")
    anim2:refresh(artifact:sprite())
    anim2:set_playback(Playback.Loop)
    artifact.update_func = function(self, dt)
        if proto.vulcan_shots >= 16 then
            proto.anim_once = true
            self:erase()
        end
    end
    return artifact
end

local function take_reverse_vulcan_action(proto)
    proto.is_acting = true --Set Proto to be acting so we don't spam shots. Well, any more than we should.
    local damage = 20
    if proto:get_rank() == Rank.SP then damage = 50 end
    local props = HitProps.new(
        damage,
        Hit.Impact,
        Element.None,
        proto:get_context(),
        Drag.None
    )
    local shot = create_reverse_vulcan_shot(proto, props)
    local target = find_best_target(proto)
    local field = proto:get_field()
    if target and not target:is_deleted() then
        field:spawn(shot, target:get_tile())
        Engine.play_audio(REVERSEVULCAN_SHOOT_AUDIO, AudioPriority.Low)
    else
        proto.is_acting = false
    end
end

local function create_devil_hand(proto, props, texture_part, is_god)
    local spell = Battle.Obstacle.new(proto:get_team()) --Create the spell.
    ObstacleInfo.set_cannot_be_manipulated(spell, true)
    spell:toggle_hitbox(true)
    local arm = proto.upper_arm
    local field = proto:get_field()
    local sound = DEVILHAND_AUDIO_1
    local direction = Direction.Down
    local target_anim = PROTO_ARM_UPPER_ANIMPATH
    spell:set_facing(proto:get_facing()) --Make sure it's going to face the right way. It's going to be on the "enemy" side compared to the virus.
    spell.x_coord = 0
    spell.y_coord = 0
    if texture_part == "arm_lower" then
        sound = DEVILHAND_AUDIO_2
        direction = proto:get_facing()
        arm = proto.lower_arm
        target_anim = PROTO_ARM_LOWER_ANIMPATH
    else
        spell.y_coord = -54.0
        if spell:get_facing() == Direction.Right then
            spell.x_coord = -38.0
        else
            spell.x_coord = 38.0
        end
        spell:set_offset(spell.x_coord, spell.y_coord)
    end
    local state = "ATTACK"
    if is_god then state = "ATTACK_GOD" end
    spell:set_health(99999)
    spell:set_hit_props(props)
    local virus_def = Battle.DefenseVirusBody.new()
    spell:add_defense_rule(virus_def)
    spell.spell_defense = create_claw_defense()
    spell:add_defense_rule(spell.spell_defense)
    spell:set_texture(arm:get_texture()) --Copying the texture of the arm.
    spell:sprite():set_layer(-4) --Needs to spawn "over" the player it's attacking.
    local spell_animation = spell:get_animation()
    spell_animation:load(target_anim)
    spell_animation:set_state(state) --Set the state to attack instead of idle.
    spell_animation:refresh(spell:sprite())
    spell_animation:set_playback(Playback.Loop)
    spell.slide_started = false
    spell.cooldown = 20 --Wait for 20 frames before moving to attack.
    spell.spawned_other_claw = false
    spell.play_sound = true
    spell.obstacle_hit = false
    local round = function(val)
        if facing == Direction.Right then
            return math.floor(val)
        else
            return math.ceil(val)
        end
    end
    spell.multiplier = spell:get_offset().x
    spell.mult_timer = 0
    spell.mult_x = 0
    spell.x_speed = 10
    if spell:get_facing() == Direction.Left then
        spell.x_speed = -10
    end
    spell.y_speed = 16
    spell.spawn_next = false
    --local cur_y = nil
    local other_query = function(o)
        return Battle.Obstacle.from(o) ~= nil and o:get_health() > 0 and not o:is_team(proto:get_team())
    end
    spell.update_func = function(self, dt)
        if proto:is_deleted() then
            self:erase()
        end
        if self:is_deleted() then
            --if texture_part == "arm_lower" then
                --self.spawn_next = true
            --end
            return true
        end
        --if self.spawn_next then return end
        if self.cooldown <= 0 then
            if self.play_sound then
                Engine.play_audio(sound, AudioPriority.Low)
                self.play_sound = false
            end
            local tile = self:get_tile()
            if texture_part == "arm_upper" and tile:y() == 2 then proto.is_acting = false end
            if is_god and texture_part == "arm_upper" and not tile:is_edge() and self:is_team(tile:get_tile(self:get_facing_away(), 1):get_team()) then
                tile:set_team(self:get_team(), false)
            elseif is_god and texture_part == "arm_lower" and not self:is_team(tile:get_team()) and not tile:is_hole() then
                tile:set_state(proto.godhand_tile_list[proto.godhand_tile_index])
            end
            local tileWidth = tile:width()/2
            local tileHeight = tile:height()/2
            tile:attack_entities(self)
            if texture_part == "arm_upper" then
                --cur_y = self:get_tile():y()
                self.y_coord = self.y_coord + self.y_speed
                if self:get_tile():y() >= 4 then
                    if round(self.y_coord) >= 54.0 then
                        self:delete()
                    end
                else
                    if self:get_tile():y() == 3 then
                        --return true
                    end
                    --if round(self.y_coord) >= -54.0 and #self:get_tile():find_entities(other_query) < 0 then
                    if round(self.y_coord) >= (-54.0 + tileHeight) and self:get_tile(Direction.Down, 1) ~= nil and #self:get_tile(Direction.Down, 1):find_entities(other_query) > 0 then
                        self.obstacle_hit = true
                        self:delete()
                    elseif round(self.y_coord) >= (-54.0 + tileHeight) then
                        if self:get_tile(Direction.Down, 1) == nil and not self:get_tile(Direction.Up, 1):is_edge() then
                            self:delete()
                        else
                            if self:get_tile():y() ~= 0 then
                                if is_god then
                                    drop_trace_fx(self, {220, 170, 17}, ColorMode.Multiply, ColorMode.Additive)
                                else
                                    drop_trace_fx(self, {0, 50, 150}, ColorMode.Multiply, ColorMode.Additive)
                                end
                            end
                            self:teleport(self:get_tile(Direction.Down, 1), ActionOrder.Immediate)
                            self.y_coord = -54.0 - tileHeight
                        end
                    end
                end
                self.mult_timer = self.mult_timer + 1
                if self.mult_timer < 4 then
                    self.mult_x = -6
                elseif self.mult_timer >= 4 and self.mult_timer < 7 then
                    self.mult_x = -4
                elseif self.mult_timer >= 7 and self.mult_timer < 10 then
                    self.mult_x = -2
                elseif self.mult_timer >= 10 and self.mult_timer < 13 then
                    self.mult_x = 0
                elseif self.mult_timer >= 13 and self.mult_timer < 17 then
                    self.mult_x = 2
                elseif self.mult_timer >= 17 and self.mult_timer < 20 then
                    self.mult_x = 4
                elseif self.mult_timer >= 17 then
                    self.mult_x = 6
                end
                self.multiplier = self.multiplier + self.mult_x
                self:set_offset(round(self.multiplier), self.y_coord)
            else
                self.x_coord = self.x_coord + self.x_speed
                if self:get_facing() == Direction.Right then
                    if round(spell.x_coord) >= tileWidth then
                        if self:get_tile(Direction.Right, 1) ~= nil and #self:get_tile(Direction.Right, 1):find_entities(other_query) > 0 then
                            self.obstacle_hit = true
                            self:delete()
                        else
                            if not self:get_tile():is_edge() then
                                self:teleport(self:get_tile(Direction.Right, 1), ActionOrder.Immediate)
                                self.x_coord = -tileWidth
                            else
                                self:delete()
                            end
                        end
                    --elseif round(spell.x_coord) >= 0 and round(spell.x_coord) < tileWidth and #self:get_tile():find_entities(other_query) < 0 then
                    --    self.obstacle_hit = true
                    --    self:delete()
                    end
                elseif self:get_facing() == Direction.Left then
                    if round(spell.x_coord) <= -tileWidth then
                        if self:get_tile(Direction.Left, 1) ~= nil and #self:get_tile(Direction.Left, 1):find_entities(other_query) > 0 then
                            self.obstacle_hit = true
                            self:delete()
                        else
                            if not self:get_tile():is_edge() then
                                self:teleport(self:get_tile(Direction.Left, 1), ActionOrder.Immediate)
                                self.x_coord = tileWidth
                            else
                                self:delete()
                            end
                        end
                    --elseif round(spell.x_coord) <= 0 and round(spell.x_coord) > -tileWidth and #self:get_tile():find_entities(other_query) < 0 then
                    --    self.obstacle_hit = true
                    --    self:delete()
                    end
                end
                self:set_offset(self.x_coord, self.y_coord)
            end
        else
            self.cooldown = self.cooldown - 1
        end
    end
    spell.attack_func = function(self, other)
        if Battle.Obstacle.from(other) == nil then
            --[[
			if Battle.Player.from(proto) ~= nil then
				Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
			end
            ]]
		else
			Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
		end
    end
    spell.collision_func = function(self, other)
        local check = Battle.Obstacle.from(other) and other:get_health() > 0
        if check ~= nil then self:delete() end
    end
    spell.delete_func = function(self)
        if not arm:is_deleted() then
            if texture_part == "arm_lower" or self.obstacle_hit then
                proto.upper_arm:reveal()
                proto.upper_arm:toggle_hitbox(true)
                proto.upper_arm:share_tile(false)
                proto.lower_arm:reveal()
                proto.lower_arm:toggle_hitbox(true)
                proto.lower_arm:share_tile(false)
                proto.is_acting = false
            end
            self:erase()
        else
            self:erase()
        end
    end
    spell.can_move_to_func = function(tile)
        return true
    end

    return spell
end

local function take_devil_hand_action(proto, texture_part, is_god)
    proto.is_acting = true --Set Proto to acting so we don't spam claws.

    local field = proto:get_field() --Get the field so we can spawn the spell.
    local mob_move1 = create_mob_move("4") --Create an artifact to visually warp the claw.
    local mob_move2 = create_mob_move("5") --Create an artifact to visually warp the claw.
    local damage = 50
    if proto:get_rank() == Rank.SP then damage = 100 end
    local props = HitProps.new(
        damage,
        Hit.Impact | Hit.Flinch | Hit.Flash,
        Element.None,
        proto:get_context(),
        Drag.None
    )

    local spell = create_devil_hand(proto, props, texture_part, is_god)
    local target = find_best_target(proto) --Get the player to attack them.
    if target and not target:is_deleted() then
        local target_tile = target:get_tile() --Get their tile.
        local desired_tile = nil
        if texture_part == "arm_upper" then
            if proto:get_facing() == Direction.Right then
                mob_move2:set_offset(-38,-54)
            else
                mob_move2:set_offset(38,-54)
            end
            proto.upper_arm:hide() --Hide the upper arm. We're going to be spawning a spell that looks like it.
            proto.upper_arm:toggle_hitbox(false)
            proto.upper_arm:share_tile(true)
            if is_god then
                if proto:get_facing() == Direction.Right then
                    desired_tile = field:tile_at(4, 0) --Hover over the player's fourth column if facing right
                else
                    desired_tile = field:tile_at(3, 0) --Hover over the player's third column if facing left
                end
            else
                desired_tile = field:tile_at(target_tile:x(), 0) --Hover on the edge tile above them.
            end
            field:spawn(mob_move1, proto.upper_arm:get_tile()) --Spawn the artifact as we hide the arm so it looks good.
        elseif texture_part == "arm_lower" then
            proto.lower_arm:hide() --Hide the upper arm. We're going to be spawning a spell that looks like it.
            proto.lower_arm:toggle_hitbox(false)
            proto.lower_arm:share_tile(true)
            local goal_x = 3
            if proto:get_facing() == Direction.Left then goal_x = 4 end
            desired_tile = field:tile_at(goal_x, target_tile:y())
            field:spawn(mob_move1, proto.lower_arm:get_tile()) --Spawn the artifact as we hide the arm so it looks good.
        end
        local other_query = function(o)
            return Battle.Obstacle.from(o) ~= nil and o:get_health() > 0 and not o:is_team(proto:get_team())
        end
        local list = desired_tile:find_entities(other_query)
        if desired_tile and #list == 0 then
            field:spawn(mob_move2, desired_tile) --Spawn the artifact as we hide the arm so it looks good.
            field:spawn(spell, desired_tile)
        else
            proto.is_acting = false
        end
    else
        proto.is_acting = false
    end
end

function package_init(self)
    self.is_acting = false
    self.vulcan_shots = 0
    self.anim_once = true
    self:set_name("Proto")
    self.health = 2000
    if self:get_rank() == Rank.SP then self.health = 3000 end
    self:set_health(self.health)
    self:set_height(55)
    self:set_texture(PROTO_CORE_TEXTURE)
    self:set_float_shoe(true)

    self.core_anim = self:get_animation()
    self.core_anim:load(PROTO_CORE_ANIMPATH)
    self.core_anim:set_state("CORE")
    self.core_anim:set_playback(Playback.Loop)
    self.core_anim:refresh(self:sprite())
    self.core_anim:set_playback_speed(0)
    
    local armor = self:create_node() --Nodes automatically attach to what you create them off of. No need to spawn!
    armor:set_texture(self:get_texture()) --Just set their texture...
    armor:set_layer(-3) --Set their layer, they're already a sprite...
    self.armor_anim = Engine.Animation.new(PROTO_CORE_ANIMPATH) --And they have no get_animation, so we create one...
    self.armor_anim:copy_from(self:get_animation()) --Load or copy the animation and do the normal stuff...
    self.armor_anim:set_state("ARMOR_IDLE")
    self.armor_anim:refresh(armor)
    self.armor_anim:set_playback(Playback.Loop)
    self.armor_anim:set_playback_speed(0)

    local pool = self:create_node() --Need one for the pool too.
    pool:set_texture(PROTO_POOL_TEXTURE)
    pool:set_layer(3)
    self.pool_anim = Engine.Animation.new(PROTO_POOL_ANIMPATH)
    self.pool_anim:set_state("0")
    self.pool_anim:refresh(pool)
    self.pool_anim:set_playback(Playback.Loop)

    local ref = self
    --This is how we animate nodes.
    self.animate_component = Battle.Component.new(self, Lifetimes.Battlestep)
    self.animate_component.update_func = function(self, dt)
        ref.armor_anim:update(dt, armor)
        ref.pool_anim:update(dt, pool)
    end

    self:register_component(self.animate_component)

    self.def = Battle.DefenseVirusBody.new() -- lua owns this, so we need to keep it alive
    self:add_defense_rule(self.def)
    self.goop_defense = Battle.DefenseRule.new(2, DefenseOrder.CollisionOnly)
    self.goop_health = 40
    self.previous_goop_health = 40
    self.regen_component = Battle.Component.new(self, Lifetimes.Battlestep)
    self.regen_component.cooldown = 0
    self.regen_component.cooldown_max = 240
    self.regen_component.update_func = function(self, dt)
        if self.cooldown < 0 then
            ref.goop_health = math.min(40, ref.goop_health + 20)
            self.cooldown = self.cooldown_max
        else
            self.cooldown = self.cooldown - 1
        end
    end

    self.shake_component = Battle.Component.new(self, Lifetimes.Battlestep)
    self.shake_component.timer = 0
    self.shake_component.update_func = function(self)
        if self.timer > 0 then
            debug_print("SHAKING")
            self.timer = self.timer - 1
            ref:shake_camera(10, 0.05)
        end
    end
    self:register_component(self.shake_component)

    local state_table = {
        "COIL_SPAWN", 
        "COIL_ATTACK",
        "COIL_RETREAT",
        "ROCKET_SPAWN",
        "VULCAN_IDLE",
        "VULCAN_ATTACK"
      }
      
    local check_state = "COIL_SPAWN" -- try replacing with one of the above
    
    local function is_any(item, set)
        for k,v in pairs(set) do
            if item == v then return true end
        end
    
        return false
    end
    self.goop_animation = Battle.Component.new(self, Lifetimes.Battlestep)
    self.goop_animation.update_func = function(self, dt)
        local check_state = ref.core_anim:get_state()
        if not ref.sigma_attack and not ref.omega_attack and not is_any(check_state, state_table) then
            if ref.goop_health ~= ref.previous_goop_health then
                if ref.goop_health <= 0 and check_state ~= "CORE_VULNERABLE_2" then
                    ref.core_anim:set_state("CORE_DAMAGE_2")
                    ref.core_anim:on_frame(3, function()
                        ref.is_vulnerable = true
                    end)
                    ref.core_anim:on_complete(function()
                        ref:set_float_shoe(false)
                        ref.core_anim:set_state("CORE_VULNERABLE_2")
                        ref.core_anim:set_playback(Playback.Loop)
                    end)
                elseif ref.goop_health == 20 and check_state ~= "CORE_VULNERABLE" then
                    ref.core_anim:set_state("CORE_DAMAGE")
                    ref:set_float_shoe(true)
                    ref.core_anim:on_frame(2, function()
                        ref.is_vulnerable = false
                    end)
                    ref.core_anim:on_complete(function()
                        ref.core_anim:set_state("CORE_VULNERABLE")
                        ref.core_anim:set_playback(Playback.Loop)
                    end)
                elseif ref.goop_health == 40 and check_state ~= "CORE" then
                    ref.core_anim:set_state("CORE_DAMAGE")
                    ref:set_float_shoe(true)
                    ref.core_anim:set_playback(Playback.Reverse)
                    ref.core_anim:on_frame(2, function()
                        ref.is_vulnerable = false
                    end)
                    ref.core_anim:on_complete(function()
                        ref.core_anim:set_state("CORE")
                        ref.core_anim:set_playback(Playback.Loop)
                    end)
                end
            end
        end
        ref.previous_goop_health = ref.goop_health
    end
    self:register_component(self.goop_animation)
    self:register_component(self.regen_component)
    self.is_vulnerable = false
    self.goop_defense.can_block_func = function(judge, attacker, defender)
        if not ref.is_vulnerable then
            judge:block_damage()
            local props = attacker:copy_hit_props()
            props.damage = math.min(20, props.damage)
            attacker:set_hit_props(props)
            if ref.goop_health > 20 then
                ref.goop_health = math.max(20, ref.goop_health - props.damage)
            else
                ref.goop_health = math.max(0, ref.goop_health - props.damage)
            end
        end
    end
    self:add_defense_rule(self.goop_defense)
    self.upper_arm = Battle.Obstacle.new(self:get_team())
    ObstacleInfo.set_cannot_be_manipulated(self.upper_arm, true)
    self.upper_arm:set_texture(PROTO_ARM_UPPER_TEXTURE)
    self.upper_arm:set_health(99999)
    self.upper_arm_anim = self.upper_arm:get_animation()
    self.upper_arm_anim:load(PROTO_ARM_UPPER_ANIMPATH)
    self.upper_arm_anim:set_state("IDLE")
    self.upper_arm_anim:refresh(self.upper_arm:sprite())
    self.upper_arm_anim:set_playback(Playback.Loop)
    self.upper_arm:sprite():set_layer(4)
    self.upper_arm_anim:set_playback_speed(0)
    self.lower_arm = Battle.Obstacle.new(self:get_team())
    ObstacleInfo.set_cannot_be_manipulated(self.lower_arm, true)
    self.lower_arm:set_health(99999)
    self.lower_arm:set_texture(PROTO_ARM_LOWER_TEXTURE)
    self.lower_arm_anim = self.lower_arm:get_animation()
    self.lower_arm_anim:load(PROTO_ARM_LOWER_ANIMPATH)
    self.lower_arm_anim:set_state("IDLE")
    self.lower_arm_anim:refresh(self.lower_arm:sprite())
    self.lower_arm_anim:set_playback(Playback.Loop)
    self.lower_arm:sprite():set_layer(-4)
    self.lower_arm_anim:set_playback_speed(0)
    
    self.flare = nil
    self.flare_cooldown = 8

    local reserving_obstacle = Battle.Obstacle.new(self:get_team())

    local field = nil
    self.battle_start_func = function()
        self.core_anim:set_playback_speed(1)
        self.armor_anim:set_playback_speed(1)
        self.upper_arm_anim:set_playback_speed(1)
        self.lower_arm_anim:set_playback_speed(1)

        field:spawn(reserving_obstacle, 0,0)

        local friends_list = field:find_characters(function(ent)
            return ent and self:is_team(ent:get_team())
        end)
        -- local fix_tile_component = Battle.Component.new()
        local x_start = 1
        local x_mid = 1
        local x_end = x_start+2
        if self:get_facing() == Direction.Left then
            x_start = field:width()
            x_mid = -1
            x_end = x_start-2
        end
        for x = x_start, x_end, x_mid do
            for y=1, 3, 1 do
                local tile = field:tile_at(x, y)
                if not (x ~= x_end and y ~= math.ceil(field:height()/2)) then
                    if tile:get_team() == self:get_team() then
                        field:tile_at(x,y):reserve_entity_by_id(reserving_obstacle:get_id())
                        --[[
                        for c=1, #friends_list, 1 do
                            field:tile_at(x,y):reserve_entity_by_id(tonumber(friends_list[c]:get_id()))
                        end
                        ]]
                    end
                end
            end
        end
    end
    self.delete_func = function(self)
        reserving_obstacle:erase()
    end
    self.on_spawn_func = function()
        field = self:get_field()
        self.upper_arm:add_defense_rule(create_claw_defense(self.upper_arm))
        self.upper_arm:set_team(self:get_team())
        self.upper_arm:set_facing(self:get_facing())
        field:spawn(self.upper_arm, self:get_tile(Direction.join(self:get_facing(), Direction.Up), 1))
        self.lower_arm:add_defense_rule(create_claw_defense(self.lower_arm))
        self.lower_arm:set_team(self:get_team())
        self.lower_arm:set_facing(self:get_facing())
        field:spawn(self.lower_arm, self:get_tile(self:get_facing_away(), 1))
    end
    self.can_move_to_func = function(tile)
        return false
    end
    self.cooldown = 150
    self.vulcan_attack = false
    self.omega_attack = false
    self.sigma_attack = false
    self.sigma_count = 0
    self.proto_arm = nil
    self.proto_arm_type = {"SIGMA", "OMEGA"}
    self.proto_arm_index = math.random(1,2)
    self.attack_index = 1
    self.attack_reversevulcan = "REVERSE VULCAN"
    self.attack_redeyesdelete = "RED EYES DELETE"
    self.attack_protoarm = "PROTO ARM"
    self.attack_godhand = "GOD HAND"
    self.sigma_state = {"SINGLE ROW", "DOUBLE ROW"}
    self.sigma_index = 1
    self.set_new_pattern = true
    self.pattern = {
        "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "CHOOSE ATTACK"
    }
    self.pattern_index = 1
    self.devil_hand_list = {"arm_upper", "arm_lower"}
    self.devil_hand_index = 1
    self.godhand_tile_list = {TileState.Poison, TileState.Ice, TileState.Cracked}
    self.godhand_tile_index = math.random(1, #self.godhand_tile_list)
    local has_changed_armor = false
    local activity = self.pattern[self.pattern_index]
    local rank = self:get_rank()
    self.update_func = function(self, dt)
        if self:is_deleted() then
            self.upper_arm:delete()
            self.lower_arm:delete()
            return
        end
        if self.cooldown <= 0 then
            if not self.is_acting then
                if not has_changed_armor and self:get_health() < math.floor(self.health/2) and self.armor_anim:get_state() == "ARMOR_IDLE" then
                    self.armor_anim:set_state("ARMOR_IDLE_FAST")
                    self.armor_anim:set_playback(Playback.Loop)
                end
                activity = self.pattern[self.pattern_index]
                if self.vulcan_attack then activity = "REVERSE VULCAN" end
                if activity == "DEVIL HAND" then
                    debug_print("activity: DEVIL HAND")
                    take_devil_hand_action(self, self.devil_hand_list[self.devil_hand_index], false)
                    self.pattern_index = self.pattern_index + 1
                    debug_print("pattern_index: "..self.pattern_index)
                    self.devil_hand_index = self.devil_hand_index + 1
                    if self.devil_hand_index > #self.devil_hand_list then self.devil_hand_index = 1 end
                    self.cooldown = 40
                elseif activity == "GOD HAND" then
                    debug_print("activity: GOD HAND")
                    take_devil_hand_action(self, self.devil_hand_list[self.devil_hand_index], true)
                    self.pattern_index = self.pattern_index + 1
                    debug_print("pattern_index: "..self.pattern_index)
                    self.devil_hand_index = self.devil_hand_index + 1
                    if self.devil_hand_index > #self.devil_hand_list then self.devil_hand_index = 1 end
                    self.godhand_tile_index = self.godhand_tile_index + 1
                    if self.godhand_tile_index > #self.godhand_tile_list then self.godhand_tile_index = 1 end
                    self.cooldown = 40
                elseif activity == "REVERSE VULCAN" then
                    debug_print("activity: REVERSE VULCAN")
                    if self.vulcan_attack and self.vulcan_shots < 16 then
                        take_reverse_vulcan_action(self)
                        self.cooldown = 13
                    end
                    if self.anim_once and self.vulcan_shots < 16 then
                        self.anim_once = false
                        self.armor_anim:set_state("VULCAN_REVEAL")
                        Engine.play_audio(REVERSEVULCAN_SPAWN_AUDIO, AudioPriority.Low)
                        self.armor_anim:on_complete(function()
                            self.armor_anim:set_state("VULCAN PAUSE")
                            self.armor_anim:on_complete(function()
                                self.armor_anim:set_state("VULCAN_SHOOT")
                                self.armor_anim:set_playback(Playback.Loop)
                                self.vulcan_attack = true
                                self.flare = create_reverse_vulcan_flare(self)
                                field:spawn(self.flare, self:get_tile())
                            end)
                        end)
                    elseif self.anim_once and self.vulcan_shots >= 16 then
                        self.anim_once = false
                        self.armor_anim:set_state("VULCAN_HIDE")
                        self.armor_anim:on_complete(function()
                            if self:get_health() < math.floor(self.health/2) then
                                self.armor_anim:set_state("ARMOR_IDLE_FAST")
                            else
                                self.armor_anim:set_state("ARMOR_IDLE")
                            end
                            self.armor_anim:set_playback(Playback.Loop)
                            self.pattern_index = self.pattern_index + 1
                            debug_print("pattern_index: "..self.pattern_index)
                            self.vulcan_attack = false
                            self.vulcan_shots = 0
                            self.anim_once = true
                            self.cooldown = 23
                        end)
                    end
                elseif activity == "RED EYES DELETE" then
                    debug_print("activity: RED EYES DELETE")
                    take_red_eye_action(self, "ATTACK_CHARGE")
                    self.pattern_index = self.pattern_index + 1
                    debug_print("pattern_index: "..self.pattern_index)
                elseif activity == "PROTO ARM" then
                    debug_print("activity: PROTO ARM")
                    if self.sigma_attack and self.sigma_count < 16 then
                        self.proto_arm = take_proto_arm_action(self, self.proto_arm_type[self.proto_arm_index])
                    end
                    if self.sigma_count >= 16 then
                        self.sigma_count = 0
                        self.sigma_attack = false
                        if self.proto_arm ~= nil then
                            self.proto_arm:delete()
                            self.proto_arm = nil
                        end
                        self.core_anim:set_state("COIL_RETREAT")
                        self.core_anim:on_complete(function()
                            self.core_anim:set_state("CORE")
                            self.core_anim:set_playback(Playback.Loop)
                            end_proto_arm(self)
                        end)
                    end
                    if self.anim_once then
                        self.upper_arm:hide()
                        self.lower_arm:hide()
                        self.upper_arm:toggle_hitbox(false)
                        self.lower_arm:toggle_hitbox(false)
                        self.anim_once = false
                        if self.proto_arm_type[self.proto_arm_index] == "SIGMA" then
                            Engine.play_audio(STONECUBE_AUDIO, AudioPriority.Low)
                            self.core_anim:set_state("COIL_SPAWN")
                            self.core_anim:on_complete(function()
                                self.core_anim:set_state("COIL_ATTACK")
                                self.core_anim:set_playback(Playback.Loop)
                                self.sigma_attack = true
                            end)
                        elseif self.proto_arm_type[self.proto_arm_index] == "OMEGA" then
                            self.omega_attack = true
                            Engine.play_audio(STONECUBE_AUDIO, AudioPriority.Low)
                            self.core_anim:set_state("ROCKET_SPAWN")
                            self.core_anim:on_frame(6, function()
                                take_proto_arm_action(self, self.proto_arm_type[self.proto_arm_index])
                            end)
                            self.core_anim:on_complete(function()
                                self.core_anim:set_state("CORE")
                                self.core_anim:set_playback(Playback.Loop)
                                end_proto_arm(self)
                            end)
                        end
                    end
                elseif activity == "CHOOSE ATTACK" then
                    debug_print("activity: CHOOSE ATTACK")
                    choose_attack(self)
                end
                if self.pattern_index > #self.pattern then
                    debug_print("reset to 1")
                    self.pattern_index = 1
                    self.pattern = {"DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "DEVIL HAND", "CHOOSE ATTACK"}
                end
                keep_omega = false
            end
        else
            self.cooldown = self.cooldown - 1
        end
    end
end

function create_effect(effect_facing, effect_texture, effect_animpath, effect_state, offset_x, offset_y, layer, field, tile)
    local hitfx = Battle.Artifact.new()
    hitfx:set_facing(effect_facing)
    hitfx:set_texture(effect_texture, true)
    hitfx:set_offset(offset_x, offset_y)
    local hitfx_sprite = hitfx:sprite()
    hitfx_sprite:set_layer(layer)
    local hitfx_anim = hitfx:get_animation()
	hitfx_anim:load(effect_animpath)
	hitfx_anim:set_state(effect_state)
	hitfx_anim:refresh(hitfx_sprite)
    hitfx_anim:on_complete(function()
        hitfx:erase()
    end)
    field:spawn(hitfx, tile)

    return hitfx
end