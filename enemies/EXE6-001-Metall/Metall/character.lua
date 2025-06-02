local print_debug = false

local AUDIO_DAMAGE_ENEMY = Engine.load_audio(_folderpath.."sfx/EXE6_50.ogg", true)
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."sfx/EXE6_131.ogg", true)

local CHARACTER_TEXTURE = Engine.load_texture(_folderpath.."gfx/battle.grayscaled.png")
local CHARACTER_ANIMPATH = _folderpath.."gfx/battle.animation"

local SHOCKWAVE_TEXTURE = Engine.load_texture(_folderpath.."gfx/shockwave.grayscaled.png")
local SHOCKWAVE_PALETTE = Engine.load_texture(_folderpath.."gfx/palette/shockwave.png")
local SHOCKWAVE_ANIMPATH = _folderpath.."gfx/shockwave.animation"
local MOB_MOVE_TEXTURE = Engine.load_texture(_folderpath.."gfx/mob_move.grayscaled.png")
local MOB_MOVE_PALETTE = Engine.load_texture(_folderpath.."gfx/palette/mob_move.png")
local MOB_MOVE_ANIMPATH = _folderpath.."gfx/mob_move.animation"
local GUARD_TEXTURE = Engine.load_texture(_folderpath.."gfx/guard.grayscaled.png")
local GUARD_PALETTE = Engine.load_texture(_folderpath.."gfx/palette/guard.png")
local GUARD_ANIMPATH = _folderpath.."gfx/guard.animation"

local GUARD_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE6_6.ogg", true)
local SHOCKWAVE_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE6_277.ogg", true)

local MobTracker = include("mob_tracker.lua")
local left_mob_tracker = MobTracker:new()
local right_mob_tracker = MobTracker:new()

local Chip161 = include("chips/EXE6-161-Recovery150/recovery/recovery.lua")
Chip161.recover_hp = 150
local Chip171 = include("chips/EXE6-171-Sanctuary/stage/stage.lua")
Chip171.type = 2
local Chip179 = include("chips/EXE6-179-Invisible/invisible/invisible.lua")

local function debug_print(text)
    if print_debug then
        print("[Metall] "..text)
    end
end

--(Function by Alrysc)
local function graphic_init(g_type, x, y, texture, animation, state, anim_playback, layer, user, facing, flip)
    flip = flip or false
    facing = facing or nil
    
    local graphic = nil
    if g_type == "artifact" then 
        graphic = Battle.Artifact.new()
    elseif g_type == "spell" then 
        graphic = Battle.Spell.new(user:get_team())
    end

    if layer then
        graphic:sprite():set_layer(layer)
    end
    graphic:never_flip(flip)
    if texture then
        graphic:set_texture(texture, false)
    end
    if facing then
        graphic:set_facing(facing)
    end
    --[[
    if user:get_facing() == Direction.Left then 
        x = x * -1
    end]]
    graphic:set_offset(x, y)
    if animation then
        graphic:get_animation():load(animation)
    end
    if state then
        graphic:get_animation():set_state(state)
    end
    graphic:get_animation():refresh(graphic:sprite())
    if anim_playback then
        graphic:get_animation():set_playback(anim_playback)
    end

    return graphic
end

function spawn_shockwave(user, tile)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end
        local spell = graphic_init("spell", 0, 0, SHOCKWAVE_TEXTURE, SHOCKWAVE_ANIMPATH, user.shockwave_state, Playback.Once, -3, user, user:get_facing())
        spell:set_palette(SHOCKWAVE_PALETTE)
        spell:set_hit_props(
            HitProps.new(
                user.damage_shockwave,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                Element.None,
                user:get_context(),
                Drag.None
            )
        )
        spell:get_animation():on_complete(function() spell:erase() end)
        spell.frames = 0
        spell.on_spawn_func = function(self)
            debug_print("ShockWave spawned on tile ("..tile:x()..";"..tile:y()..")")
            Engine.play_audio(SHOCKWAVE_AUDIO, AudioPriority.Low)
            if user.replacement_panel then -- Replaces tile only on spawn.
                if user.replacement_panel == TileState.Cracked and self:get_tile():is_cracked() then
                    self:get_tile():set_state(TileState.Broken)-- Breaks tile if is cracked already.
                else
                    self:get_tile():set_state(user.replacement_panel)
                end
            end
        end
        spell.update_func = function(self)
            self:get_tile():attack_entities(self)
            if not self:get_tile():is_walkable() then
                self:erase()
            end
            self.frames = self.frames + 1
            if self.frames >= 1 then
                self:highlight_tile(Highlight.Solid)
                if self.frames == user.frames_before_new_attack then
                    tile = tile:get_tile(self:get_facing(), 1)
                    spawn_next()
                end
            end
        end
        spell.attack_func = function(self, other)
            debug_print("ShockWave attacked tile ("..self:get_tile():x()..";"..self:get_tile():y()..")")
            if Battle.Obstacle.from(other) == nil then
                --if Battle.Player.from(user) ~= nil then
                    --Engine.play_audio(AUDIO_DAMAGE_ENEMY, AudioPriority.Low)
                --end
            else
                Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
            end
        end
        spell.battle_end_func = function(self)
            self:erase()
        end
        user:get_field():spawn(spell, tile)
    end
    spawn_next()
end

function get_tracker_from_direction(facing)
    if facing == Direction.Left then
        return left_mob_tracker
    elseif facing == Direction.Right then
        return right_mob_tracker
    end
end

function advance_a_turn_by_facing(facing)
    local mob_tracker = get_tracker_from_direction(facing)
    return mob_tracker:advance_a_turn()
end

function get_active_mob_id_for_same_direction(facing)
    local mob_tracker = get_tracker_from_direction(facing)
    return mob_tracker:get_active_mob()
end

function add_enemy_to_tracking(enemy)
    local facing = enemy:get_facing()
    local id = enemy:get_id()
    local mob_tracker = get_tracker_from_direction(facing)
    mob_tracker:add_by_id(id)
end

function remove_enemy_from_tracking(enemy)
    local facing = enemy:get_facing()
    local id = enemy:get_id()
    local mob_tracker = get_tracker_from_direction(facing)
    mob_tracker:remove_by_id(id)
end

function package_init(self, character_info)
    debug_print("package_init called")
    -- Required function, main package information

    -- Load character resources
    self.texture = CHARACTER_TEXTURE
    self.animation = self:get_animation()
    self.animation:load(CHARACTER_ANIMPATH)

    -- Load extra resources

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_health(character_info.hp)
    self:set_texture(self.texture, true)
    self:set_height(28)
    self:share_tile(false)
    self:set_explosion_behavior(2, 1, false)
    self:set_offset(0,0)
    self:set_palette(Engine.load_texture(_folderpath.."gfx/palette/battle-"..self:get_rank()..".png"))

    -- DefenseRules
    --self.defense = Battle.DefenseVirusBody.new()
    --self:add_defense_rule(self.defense)
    local super_armor = Battle.DefenseRule.new(813, DefenseOrder.CollisionOnly)
	super_armor.filter_statuses_func = function(statuses)
        if (statuses.flags & Hit.Stun == Hit.Stun) or (statuses.flags & Hit.Freeze == Hit.Freeze) then
        else
            --print("not flinching")
		    statuses.flags = statuses.flags & ~Hit.Flinch
	  	    statuses.flags = statuses.flags & ~Hit.Flash
        end
		return statuses
	end
	self:add_defense_rule(super_armor)

    -- Initial state
    self.animation:set_state("PLAYER_IDLE")
    self.animation:set_playback(Playback.Loop)
    self.damage = character_info.damage
    self.frames_between_actions = character_info.move_delay
    self.frames_before_new_attack = character_info.shockwave_frames -- lower = faster ShockWaves
    self.shockwave_state = character_info.shockwave_state -- upper = faster ShockWaves
    self.damage_shockwave = character_info.damage_shockwave
    self.can_guard = character_info.can_guard
    self.replacement_panel = character_info.replacement_panel
    self.ai_wait = 36
    self.ai_taken_turn = false

    self.battle_chip_start = false
    self.battle_chip_timer = 300
    self.battle_chip_amount = 0
    self.battle_chip = nil
    self.battle_chip_id = 0

    function check_obstacles(tile, self)
        local ob = tile:find_obstacles(function(o)
            return o:get_health() > 0 
        end)
        return #ob > 0 
    end
    function check_characters(tile, self)
        local characters = tile:find_characters(function(c)
            return c:get_id() ~= self:get_id() and c:get_health() > 0
        end)
        return #characters > 0
    end

    self.rooted = 0
    self:register_status_callback(Hit.Root, function() self.rooted = 120 end)
    self.can_move_to_func = function(tile)
        if self.rooted > 0 then return false end
        if tile:is_edge() or not tile:is_walkable() then
            return false
        end
        if(tile:is_reserved({self:get_id()})) then
            return false
        end
        --if tile == self:get_tile() then
        --    return true
        --end
        if tile:get_team() ~= self:get_team() then
            return false
        end
        return not check_obstacles(tile, self) and not check_characters(tile, self)
    end
    self.update_func = function(self)
        if self.rooted > 0 then self.rooted = self.rooted - 1 end
        if self.battle_chip_start then
            if self.battle_chip_timer > 0 then
                self.battle_chip_timer = self.battle_chip_timer - 1
            else
                if self.battle_chip_amount <= 0 then
                    self.battle_chip_start = false
                end
            end
        end
        local facing = self:get_facing()
        local field = self:get_field()
        local id = self:get_id()
        local active_mob_id = get_active_mob_id_for_same_direction(facing)
        if active_mob_id == id then
            take_turn(self)
        else
            idle_action(self)
        end

        check_collision(self)
    end
    self.battle_start_func = function(self)
        debug_print("battle_start_func called")
        if self.battle_chip_id ~= 161 then
            self.battle_chip_start = true
        end
        if left_mob_tracker:get_first_mob(false) == nil then
            left_mob_tracker:clear()
        end
        if right_mob_tracker:get_first_mob(true) == nil then
            right_mob_tracker:clear()
        end
        add_enemy_to_tracking(self)
        local field = self:get_field()
        local mob_sort_func = function(a,b)
            local met_a_tile = field:get_entity(a):get_tile()
            local met_b_tile = field:get_entity(b):get_tile()
            local var_a = (met_a_tile:x()*3)+met_a_tile:y()
            local var_b = (met_b_tile:x()*3)+met_b_tile:y()
            return var_a < var_b
        end
        left_mob_tracker:sort_turn_order(mob_sort_func)
        right_mob_tracker:sort_turn_order(mob_sort_func,true)--reverse sort direction
    end
    self.battle_end_func = function(self)
        debug_print("battle_end_func called")
        left_mob_tracker:clear()
        right_mob_tracker:clear()
    end
    self.on_spawn_func = function(self, spawn_tile)
        debug_print("on_spawn_func called")
        if self:get_rank() == Rank.V2 then
            self:set_name("Metall2")
        elseif self:get_rank() == Rank.V3 then
            self:set_name("Metall3")
            if math.random(1,16) <= 3 then
                self.battle_chip_amount = 1
                self.battle_chip = Chip179
                self.battle_chip_id = 179
                if self.battle_chip_amount == 1 then
                    print("Metall3 has a BattleChip: Invisible")
                elseif self.battle_chip_amount > 1 then
                    print("Metall3 has "..self.battle_chip_amount.." BattleChips: Invisible")
                end
            end
        elseif self:get_rank() == Rank.SP then
            if math.random(1,16) <= 3 then
                self.battle_chip_amount = 1
                self.battle_chip = Chip161
                self.battle_chip_id = 161
                if self.battle_chip_amount == 1 then
                    print("MetallSP has a BattleChip: Recovery150")
                elseif self.battle_chip_amount > 1 then
                    print("MetallSP has "..self.battle_chip_amount.." BattleChips: Recovery150")
                end
            end
        elseif self:get_rank() == Rank.Rare1 then
            self:set_name("RarMetall")
            self.battle_chip_amount = 1
            self.battle_chip = Chip161
            self.battle_chip_id = 161
            if self.battle_chip_amount == 1 then
                print("RareMetall has a BattleChip: Recovery150")
            elseif self.battle_chip_amount > 1 then
                print("RareMetall has "..self.battle_chip_amount.." BattleChips: Recovery150")
            end
        elseif self:get_rank() == Rank.Rare2 then
            self:set_name("RarMetll2")
            local chance = math.random(1,16)
            if chance <= 2 then
                self.battle_chip_amount = 1
                self.battle_chip = Chip171
                self.battle_chip_id = 171
                if self.battle_chip_amount == 1 then
                    print("RareMetall2 has a BattleChip: Sanctuary")
                elseif self.battle_chip_amount > 1 then
                    print("RareMetall2 has "..self.battle_chip_amount.." BattleChips: Sanctuary")
                end
            elseif chance <= 12 then
                self.battle_chip_amount = 1
                self.battle_chip = Chip179
                self.battle_chip_id = 179
                if self.battle_chip_amount == 1 then
                    print("RareMetall2 has a BattleChip: Invisible")
                elseif self.battle_chip_amount > 1 then
                    print("RareMetall2 has "..self.battle_chip_amount.." BattleChips: Invisible")
                end
            end
        end
        --In theory we should not need to do this as they would be cleared at the end of the last battle
        --However there is a bug in ONB V2 which causes battle_end_func to be missed sometimes.
        left_mob_tracker:clear()
        right_mob_tracker:clear()
    end
    --[[
    self.can_move_to_func = function(tile)
        debug_print("can_move_to_func called")
        return is_tile_free_for_movement(tile,self)
    end
    ]]
    self.delete_func = function(self) 
        debug_print("delete_func called")
        remove_enemy_from_tracking(self)
    end
end

function create_collision_attack(self, tile)
    local spell = Battle.Spell.new(self:get_team())
    local hit_props = HitProps.new(
        self.damage_contact,
        Hit.Impact | Hit.Flash | Hit.Flinch,
        self:get_element(), 
        self:get_context(), 
        Drag.None
    )
    spell:set_hit_props(hit_props)
    spell.update_func = function(self)
        tile:attack_entities(self)
        self:delete()
    end
    self:get_field():spawn(spell, tile)
end

function check_collision(self)
    local t = self:get_tile()
    if self.collision_available and check_characters(t, self) then 
        create_collision_attack(self, t)
    end
end

function find_target(self)
    local field = self:get_field()
    local team = self:get_team()
    local target_list = field:find_characters(function(other_character)
        return other_character:get_team() ~= team
    end)
    if #target_list == 0 then
        debug_print("No targets found!")
        return
    end
    local target_character = target_list[1]
    return target_character
end

function idle_action(self)
    if self.can_guard then
        --if the mettaur can guard, queue up a guard for after the current action
        if self.guarding_defense_rule then
            local anim = self:get_animation()
            anim:set_state("GUARDING")
        elseif not self.guard_transition then
            begin_guard(self)
        end
    end
end

function end_guard(character)
    character.guard_transition = true
    local anim = character:get_animation()
    anim:set_state("GUARD_OFF")
    anim:set_playback(Playback.Once)
    character:remove_defense_rule(character.guarding_defense_rule)
    character.guarding_defense_rule = nil
    anim:on_complete(function()
        character.guard_transition = false
        character.ai_wait = 36
	end)
end

function begin_guard(character)
    character.guard_transition = true
    local anim = character:get_animation()
    anim:set_state("GUARD_ON")
    anim:set_playback(Playback.Once)
    anim:on_complete(function()
        character.guard_transition = false
        character.guarding_defense_rule = Battle.DefenseRule.new(0, DefenseOrder.Always)
        character.guarding_defense_rule.can_block_func = function(judge, attacker, defender)
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.flags & Hit.Breaking ~= Hit.Breaking then
                --cant block breaking hits with guard
                judge:block_impact()
                judge:block_damage()
                if attacker_hit_props.damage > 0 then
                    Engine.play_audio(GUARD_AUDIO, AudioPriority.Low)
                    local offset_y = math.random(-24,-9)
                    local offset_x = math.random(-9,8) --math.random(-9,5)
                    if character:get_facing() == Direction.Left then offset_x = -offset_x end
                    local hit_fx = graphic_init("artifact", character:get_tile_offset().x+character:get_offset().x+(offset_x*2), character:get_tile_offset().y+character:get_offset().y+(offset_y*2), GUARD_TEXTURE, GUARD_ANIMPATH, "0", Playback.Once, -999, character, character:get_facing())
                    hit_fx:set_palette(GUARD_PALETTE)
                    hit_fx:get_animation():on_complete(function() hit_fx:erase() end)
                    character:get_field():spawn(hit_fx, character:get_tile())
                end
            end
        end
        character:add_defense_rule(character.guarding_defense_rule)
	end)
end

function take_turn(self)
    local id = self:get_id()
    --print("taking turn "..id)
    if self.ai_wait > 0 or self.ai_taken_turn then
        self.ai_wait = self.ai_wait - 1
        if not self.guarding_defense_rule and not self.guard_transition and not self.shockwave_action then
            local anim = self:get_animation()
            anim:set_state("PLAYER_IDLE")
        end
        return
    end
    self.ai_taken_turn = true
    
    if self.guarding_defense_rule and not self.guard_transition then
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        end_guard(self)
        return
    end

    local moved = move_towards_character(self)
    if moved then
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        return
    end
    self.shockwave_action = action_shockwave(self)
    self.shockwave_action.action_end_func = function()
        local facing = self:get_facing()
        self.ai_wait = self.frames_between_actions
        self.ai_taken_turn = false
        self.shockwave_action = nil
        advance_a_turn_by_facing(facing)
    end
    if not self.guard_transition and self.ai_wait <= 0 then
        --print("can action")
        if self.battle_chip_amount > 0 and ((self.battle_chip_id == 161 and self:get_health() <= (self:get_max_health()-(self:get_max_health()*75)/100)) or (self.battle_chip_id ~= 161 and self.battle_chip_timer <= 0)) then
            debug_print("using Chip")
            self.battle_chip_amount = self.battle_chip_amount - 1
            local chip_action = self.battle_chip.card_create_action(self)
            local props = chip_action:copy_metadata()
            if self.battle_chip_id == 161 then
                props.shortname = "Recov150"
                props.damage = 0
                props.time_freeze = false
                props.element = Element.None
                props.can_boost = false
            elseif self.battle_chip_id == 171 then
                props.shortname = "Snctuary"
                props.damage = 0
                props.time_freeze = true
                props.element = Element.None
                props.can_boost = false
            elseif self.battle_chip_id == 179 then
                props.shortname = "Invisibl"
                props.damage = 0
                props.time_freeze = true
                props.element = Element.None
                props.can_boost = false
            end
            chip_action = self.battle_chip.card_create_action(self, props)
	        chip_action:set_metadata(props)
            self:card_action_event(chip_action, ActionOrder.Voluntary)
            --chip_action.action_end_func = function()
                --self.battle_chip_timer = 300
                self.ai_taken_turn = false
            --end
        else
            debug_print("using Wave")
            action_shockwave1(self)
            --self:card_action_event(self.shockwave_action, ActionOrder.Voluntary)
        end
    end
end

function move_towards_character(self)
    self.guard_transition = true
    local target_character = find_target(self)
    local target_character_tile = target_character:get_tile()
    local tile = self:get_tile()
    local moved = false
    local target_movement_tile = nil
    if tile:y() < target_character_tile:y() then
        target_movement_tile = tile:get_tile(Direction.Down, 1)
    end
    if tile:y() > target_character_tile:y() then
        target_movement_tile = tile:get_tile(Direction.Up, 1)
    end
    local anim = self:get_animation()
    if target_movement_tile and self.can_move_to_func(target_movement_tile) then
        anim:set_state("PLAYER_MOVE")
        self:get_animation():on_frame(1, function()
            target_movement_tile:reserve_entity_by_id(self:get_id())
            if self.can_move_to_func(target_movement_tile) then
                local move_fx = graphic_init("artifact", 0, -8*2, MOB_MOVE_TEXTURE, MOB_MOVE_ANIMPATH, "0", Playback.Once, -99, self, self:get_facing(), true)
                move_fx:set_palette(MOB_MOVE_PALETTE)
                move_fx:get_animation():on_complete(function() move_fx:erase() end)
                self:get_field():spawn(move_fx, tile)
            else
                anim:set_state("PLAYER_IDLE")
                self.guard_transition = false
                return false
                --return moved
            end
        end)
        self:get_animation():on_complete(function()
            anim:set_state("PLAYER_IDLE")
            self:teleport(target_movement_tile, ActionOrder.Immediate)
            self.ai_wait = self.frames_between_actions
            self.ai_taken_turn = false
            self.guard_transition = false
            return true
            --moved = self:teleport(target_movement_tile, ActionOrder.Immediate)
            --return moved
        end)
    else
        anim:set_state("PLAYER_IDLE")
        self.guard_transition = false
        return false
        --return moved
    end
    --[[
    if target_movement_tile then
        moved = self:teleport(target_movement_tile, ActionOrder.Immediate)
        if moved then
            --print("moving")
            local move_fx = graphic_init("artifact", 0, -8*2, MOB_MOVE_TEXTURE, MOB_MOVE_ANIMPATH, "0", Playback.Once, -99, self, self:get_facing(), true)
            move_fx:set_palette(MOB_MOVE_PALETTE)
            move_fx:get_animation():on_complete(function() move_fx:erase() end)
            self:get_field():spawn(move_fx, tile)
        end
    end
    ]]
    --return moved
end

function action_shockwave(character)
    local action_name = "ShockWave"
    debug_print('action '..action_name)

    local action = Battle.CardAction.new(character, "ATTACK")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        self:add_anim_action(6, function()
            character:toggle_counter(true)
        end)
		self:add_anim_action(14, function()
            spawn_shockwave(character, character:get_tile(character:get_facing(), 1))
        end)
        self:add_anim_action(17, function()
            character:toggle_counter(false)
        end)
	end
    return action
end

function action_shockwave1(character)
    character.guard_transition = true
    local anim = character:get_animation()
    anim:set_state("ATTACK")
    anim:on_frame(6, function()
        character:toggle_counter(true)
    end)
	anim:on_frame(14, function()
        spawn_shockwave(character, character:get_tile(character:get_facing(), 1))
    end)
    anim:on_frame(17, function()
        character:toggle_counter(false)
    end)
    anim:on_complete(function()
        character.guard_transition = false
        local facing = character:get_facing()
        character.ai_wait = character.frames_between_actions
        character.ai_taken_turn = false
        character.shockwave_action = nil
        advance_a_turn_by_facing(facing)
    end)
end

--[[
function is_tile_free_for_movement(tile,character)
    --Basic check to see if a tile is suitable for a chracter of a team to move to
    if tile:get_team() ~= character:get_team() then return false end
    if not tile:is_walkable() then return false end
    local occupants = tile:find_characters(function(other_character)
        return true
    end)
    if #occupants > 0 then 
        return false
    end
    return true
end
]]

return package_init