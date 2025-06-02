local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."EXE4_270.ogg")
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."EXE4_221.ogg")

local SHADOWMAN_TEXTURE = nil
local SHADOWMAN_ANIMPATH = _folderpath.."shadowman.animation"
local BAKUEN_TEXTURE = Engine.load_texture(_folderpath.."bakuen.png")
local BAKUEN_ANIMPATH = _folderpath.."bakuen.animation"
local BAKUEN_AUDIO = Engine.load_audio(_folderpath.."EXE5_15.ogg")
local SHURIKEN_TEXTURE = Engine.load_texture(_folderpath.."shuriken.png")
local SHURIKEN_ANIMPATH = _folderpath.."shuriken.animation"
local SHURIKEN_THROW_AUDIO = Engine.load_audio(_folderpath.."EXE4_143.ogg")
local SHURIKEN_HIT_AUDIO = Engine.load_audio(_folderpath.."EXE4_353.ogg")
local SWORD_TEXTURE = Engine.load_texture(_folderpath.."swords.png")
local SWORD_ANIMPATH = _folderpath.."swords.animation"
local SWORD_AUDIO = Engine.load_audio(_folderpath.."EXE4_13.ogg")

local EFFECT_TEXTURE = Engine.load_texture(_folderpath.."effect.png")
local EFFECT_ANIMPATH = _folderpath.."effect.animation"
local SMOKE_TEXTURE = Engine.load_texture(_folderpath.."smoke.png")
local SMOKE_ANIMPATH = _folderpath.."smoke.animation"

function package_init(self)
    SHADOWMAN_TEXTURE = Engine.load_texture(_folderpath.."shadowman.png")
    self:set_name("ShadowMan")
	local rank = self:get_rank()
    self.damage = 60
    self.damage_bakuen = 60
    self.damage_shuriken = 60
    self.damage_kagebunshin = 60
    self.bakuen_frame = 10
    self.flinch_duration = 44
    self.move_count = 3

    self.next_tile = nil
    self.prev_tile = nil

    self.bunshin_attack = false
    self.do_once1 = true
    
    -- Will set to base_idle_speed normally, but go to *2 after an attack, and sometimes * 1 or * 0 after flinch
    self.base_idle_speed = 44

    -- Chance /16. I'm going to run these when the pattern is complete and when the flinch finishes, respectively
        -- These skips will be very implementation-specific, so don't use them as future references
    self.chance_to_move_four_times = 2
    self.chance_to_move_five_times = 4
    self.chance_to_skip_idle_after_flinch = 2
    self.chance_to_halve_idle_after_flinch = 3

    if rank == Rank.V1 then
        self:set_health(1000)
    elseif rank == Rank.V2 then
        self:set_name("ShadoMnV")
        self:set_health(1200)
        self.damage = 80
        self.damage_bakuen = 80
        self.damage_shuriken = 80
        self.damage_kagebunshin = 80
        self.bakuen_frame = 8
        self.flinch_duration = 36
        self.base_idle_speed = 36
    elseif rank == Rank.V3 then
        self:set_name("ShadoMnV")
        self:set_health(1500)
        self.damage = 100
        self.damage_bakuen = 100
        self.damage_shuriken = 100
        self.damage_kagebunshin = 100
        self.bakuen_frame = 7
        self.flinch_duration = 28
        self.base_idle_speed = 28
    elseif rank == Rank.SP then
        self:set_name("ShadowMn")
        self:set_health(1700)
        self.damage = 120
        self.damage_bakuen = 140
        self.damage_shuriken = 120
        self.damage_kagebunshin = 120
        self.bakuen_frame = 5
        self.flinch_duration = 20
        self.base_idle_speed = 20
    end

    self.idle_speed = self.base_idle_speed 

    self:set_texture(SHADOWMAN_TEXTURE, true)

    self:set_height(44)
    self:set_explosion_behavior(3, 1, true)
    self:set_offset(0, 0)
	self:set_facing(Direction.Left)
	self:set_element(Element.None)
    self:share_tile(false)
	self:set_float_shoe(true)
	self:set_air_shoe(false)

    local anim = self:get_animation()
    anim:load(SHADOWMAN_ANIMPATH)

    self.anim = include("enemy_base_v1/entry.lua")
    anim = self.anim
    anim:set_owner(self)
    anim:set_state("IDLE", {
        {duration=10, state="IDLE_1"},
        {duration=7, state="IDLE_2"},
        {duration=6, state="IDLE_3"},
        {duration=10, state="IDLE_4"},
        {duration=8, state="IDLE_5"},
        {duration=6, state="IDLE_6"},
    })

    anim:set_playback(Playback.Loop)
    init_boss(self)

end

--(Function by Alrysc)
-- This is to fix something that happens because I'm a cheater
--[[
    The aggressor of an attack is held in the Context object. 
    ONB leaves this aggressor unset in the Entity's Context until a CardAction is used for the first time
    So I'll immediately force a CardAction that will hopefully end immediately and not get in the way, but also will fix this
    This probably goes horribly wrong if the enemy is spawned after the mob intro, but should be fine for now otherwise
]]
function fix_context(self)
    local action = Battle.CardAction.new(self, "IDLE_1")
    action.execute_func = function()
        action:end_action()
    end

    self:card_action_event(action, ActionOrder.Immediate)
end

--(Function by Alrysc)
function init_boss(self)
    self.on_spawn_func = function(self)
        fix_context(self)
        --[[
        self.before_battle_start_animater = Battle.Artifact.new()
        self:get_field():spawn(self.before_battle_start_animater, 7, 4)
        self.before_battle_start_animater.update_func = function()
            self.anim:tick_animation()
        end
        ]]
    end

    self.battle_start_func = function(self)
        --self.before_battle_start_animater:delete()
    end

    -- Setting names here is just convenience if I want to print the state I'm in later
    self.states = {
        idle = {name = "idle", func = idle},
        move = {name = "move", func = move},
        flinch = {name = "flinch", func = flinch},
        
        start_sub_pattern = {name = "start_sub_pattern"},
        finish_sub_pattern = {name = "finish_sub_pattern"},

        bakuen = {name = "bakuen", func = bakuen},
        shuriken = {name = "shuriken", func = shuriken},
        kagebunshin = {name = "kagebunshin", func = kagebunshin},

        choose_attack = {name = "choose_attack", func = choose_attack}
    }
    
    local s = self.states

    reconstruct_pattern(self)
 
    self.pattern_index = 1
    self.in_sub_pattern = false

    self.first_act = true

    self.state_done = false

    self.state = self.pattern[1]

    self.first_flinch = true

    self.hit_func = function(from_stun)
      --  print("Hit func runs")
        self.flinching = false
        self.first_act = false
        self.state_done = false
        self.moving_to_enemy_tile = false
        if self.first_flinch then 
         --   self.state.cleanup
            self.last_state = self.state
       --     print("Hit! Set last state to ", self.state.name)
            if self.state ~= self.states.idle and self.state ~= self.states.move then 
               -- increment_pattern(self)
            end

            self.first_flinch = false
        end

        self.state = self.states.flinch

        -- This is unused for this boss
        if self.slide_component ~= nil then 
          --  print("Hit while moving.")
            self.slide_component:eject()
            self.slide_component = nil
            self:set_offset(0, 0)

            if self.slide_dest and self:get_current_tile() ~= self.slide_dest then 
            --    print("Hit before reaching destination.")
                self:get_current_tile():remove_entity_by_id(self:get_id())
                self.slide_dest:add_entity(self)
                self.slide_dest = nil
            end

        end

        flinch(self, from_stun)
    end

    self.delete_func = function(self)
        self.update_func = function(self)
            self:get_animation():set_state("STUN_1")
            self.state = self.states.flinch
        end
    end

    -- Unused for this boss
    self.moving_to_enemy_tile = false
    self.counter = 0
    self.collision_available = true

    self:register_status_callback(Hit.Stun, function() self.hit_func(true) end)
    self:register_status_callback(Hit.Flinch, self.hit_func)
    self:register_status_callback(Hit.Drag, self.hit_func)
    self:register_status_callback(Hit.Root, function() self.rooted = 120 end)

    -- Bring it back next build. For now, relying on the stun callback
    --[[
    self.on_countered = function(self)
        print("Countered")
        self:toggle_counter(false)
        self.hit_func(self)

    end
    --]]

    self.can_move_to_func = function(tile)
        if self.rooted > 0 then return false end
        if tile:is_edge() or not tile:is_walkable() then
            return false
        end
        if(tile:is_reserved({self:get_id()})) then
            return false
        end

        if not self.moving_to_enemy_tile and (tile:get_team() ~= self:get_team()) then
            return false
        end

        return not check_obstacles(tile, self) and not check_characters_true(tile, self)
    end

    self.rooted = 0
    self.update_func = function(self)
       -- print("     ", self.state.name, self:get_animation():get_state())
        if self.rooted > 0  then self.rooted = self.rooted - 1 end
        self.state.func(self)
        self.anim:tick_animation()

        -- When we tick animation, we may run increment_pattern. 
        -- The new state isn't run until next frame, so our anim state lasts one more frame when it finishes
        -- Calling our state one time to set things up will avoid this. Mostly sure this doesn't have major unintended consequences,
        -- especially as most state.func only set state and callbacks for frame 1
        -- Problem is, now I may have a frame 1 callback but I don't run it until next frame
        while self.first_act do
            self.state.func(self)
            self.anim:tick_animation()
        end
        local function query(c)
            return c:get_team() ~= team
        end
        check_collision(self)
    end
end

--(Function by Alrysc)
function create_collision_attack(self, tile)
    local spell = Battle.Spell.new(self:get_team())
   
    local hit_props = HitProps.new(
        self.damage,
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

--(Function by Alrysc)
-- TODO: When we get is_passthrough or something, check to see if target became flashing before 
    -- we are allowed to spawn another one. Don't want to instakill viruses
-- self.collision_available can do something related to that. Does nothing now
function check_collision(self)
    local t = self:get_current_tile()
    if self.collision_available and check_characters(t, self) then 
        create_collision_attack(self, t)
    end
end

--(Function by Alrysc)
function idle(self)
    if self.first_act then 
        -- This is an old check for when I extended idle time by doing two idle states in a row, when characters have an animated idle
            -- Not needed if I instead use a timer
        if self.anim:get_state() ~= "IDLE" then 
        --    print("Idle with ", self.idle_speed)
            self.anim:set_state("IDLE", {
                {duration=10, state="IDLE_1"},
                {duration=7, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=10, state="IDLE_4"},
                {duration=8, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })    
        end

        self.anim:set_playback(Playback.Loop)
        self.counter = 0

        self.first_act = false
    end

    self.counter = self.counter + 1
    if self.counter >= self.idle_speed then
        -- Extra catch for after leaving attack. Attack will double idle speed once, so making sure to reset it after
        if self.idle_speed > self.base_idle_speed then 
            self.idle_speed = self.base_idle_speed
        end

        increment_pattern(self)
    end

    --self.looped = false
    --if self.state_done then 
       -- print("State done")
        
   -- end
end

function kagebunshin(self)
    if self.first_act then
        if self.anim:get_state() ~= "IDLE" then
            self.anim:set_state("IDLE")
            --[[
            self.anim:set_state("IDLE", {
                {duration=10, state="IDLE_1"},
                {duration=7, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=10, state="IDLE_4"},
                {duration=8, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })    
            ]]
        end

        self.anim:set_playback(Playback.Loop)
        self.counter = 0
        create_effect(self:get_facing(), SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", 0, -66, true, -9, self:get_field(), self.bunshin_tile)
        local bunshin = create_effect(self:get_facing(), SHADOWMAN_TEXTURE, SHADOWMAN_ANIMPATH, "BUNSHIN_SWORD", 0, 0, false, -3, self:get_field(), self.bunshin_tile)
        local bunshinsword = create_effect(self:get_facing(), SWORD_TEXTURE, SWORD_ANIMPATH, "16", 0, 0, false, -9, self:get_field(), self.bunshin_tile)
        bunshin:get_animation():on_frame(1, function()
            Engine.play_audio(SWORD_AUDIO, AudioPriority.Low)
        end)
        bunshin:get_animation():on_frame(3, function()
            sword_hitbox(self, bunshin:get_tile(self:get_facing(), 1))
        end)
        bunshin:get_animation():on_complete(function()
            create_effect(self:get_facing(), SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", 0, -66, true, -9, self:get_field(), self.bunshin_tile)
            bunshin:erase()
        end)

        self.first_act = false
    end

    self.counter = self.counter + 1
    if self.counter >= self.base_idle_speed then
        increment_pattern(self)
    end
end

--(Function by Alrysc)
function hit()
    

end

--(Function by Alrysc)
function end_sub_pattern(self)
    while(self.in_sub_pattern)
    do
        increment_pattern(self)
    end
end

--(Function by Alrysc)
function flinch(self, from_stun)
    -- print("Flinch played")
    if self:get_current_tile() == self.next_tile then
        local orig_tile = self.next_tile
        self.next_tile:remove_entity_by_id(self:get_id())
        self.next_tile = orig_tile
        self.next_tile:add_entity(self)
        self.next_tile = nil
    elseif self:get_current_tile() == self.prev_tile then
        local orig_tile = self.prev_tile
        self.prev_tile:remove_entity_by_id(self:get_id())
        self.prev_tile = orig_tile
        self.prev_tile:add_entity(self)
        self.prev_tile = nil
    end
    -- print("I am flinching")
    if not self.flinching then 
        local frames = {}
        local flinch_time = self.flinch_duration
        if not from_stun then
            frames[1] = {duration=4, state="FLINCH_1"}
            for i=1+1, flinch_time+1+1, 4 do
                frames[i] = {duration=2, state="FLINCH_2"}
            end
            for i=2+1, flinch_time+2+1, 4 do
                frames[i] = {duration=2, state="FLINCH_3"}
            end
            for i=3+1, flinch_time+3+1, 4 do
                frames[i] = {duration=2, state="FLINCH_4"}
            end
            for i=4+1, flinch_time+4+1, 4 do
                frames[i] = {duration=2, state="FLINCH_5"}
            end
            frames[6+flinch_time] = {duration=2, state="FLINCH_6"}
            frames[7+flinch_time] = {duration=4, state="FLINCH_7"}
            frames[8+flinch_time] = {duration=4, state="FLINCH_8"}
            frames[9+flinch_time] = {duration=2, state="FLINCH_9"}
        else
            frames[1] = {duration=0, state="STUN_1"}
        end

        self.anim:set_state("FLINCH", frames)

        self.anim:on_complete(function()
            -- If we didn't just attack, we want to make sure the idle speed is correct. This is also set in the actual idle, but just for extra measure.
                -- Shouldn't be necessary
            if self.idle_speed > self.base_idle_speed and self.pattern[self.pattern_index] ~= self.states.choose_attack then 
                self.idle_speed = self.base_idle_speed
            end

            local has_skipped = false
            if self.last_state == self.states.idle then 
            --      print("Attempt skip, because last state was idle")
                has_skipped = maybe_skip_after_flinch(self)
            end

            
--         print("I am done flinching")
        --   print("Anim done")
            self.flinching = false
            self.state_done = true
            self.first_flinch = true

        --    print("Done")
            self.state_done = false
            if self.last_state ~= self.states.idle and self.last_state ~= self.states.move then 
        --     print("Last state was not idle or move", self.last_state.name)
 
                increment_pattern(self)

            
            else--if not has_skipped then 
                -- If we were in idle or move, go back to it and try again
                    -- Unless we were in a sub pattern. Still end that.
            --   print("Last state was idle or move")

                if self.in_sub_pattern then 
                    end_sub_pattern(self)
                else
                    self.state = self.last_state
                    self.first_act = true
                end
            end

        end)

    end

    self.flinching = true
end

--(Function by Alrysc)
--[[
    Chance to skip idle or halve idle time, to call after flinching 
    This works by calling increment_pattern an extra time if and only if the last state was Idle
        Remember, last state is the state we will return to after flinching
        Some extra work will need to be done in the self.anim:on_complete of flinch if this is to work with sub patterns. This boss doesn't use them, so it was omitted
    
    Currently, the skip is implemented as setting idle time to 0
    
    A future choice for this function: after calling this function, self.state *may* increment, obsoleting our last state pointer. Returns true if this does happen
        There is a possible additional side effect that the idle time will instead be changed, in which case, last state is preserved and false is returned
]]
function maybe_skip_after_flinch(self)
    local chance_halve = self.chance_to_halve_idle_after_flinch
    local chance_skip = self.chance_to_skip_idle_after_flinch
    local max = chance_halve + chance_skip + (16 - chance_halve - chance_skip)

    local r = math.random(1, max)
    if r <= chance_halve then 
        self.idle_speed = math.floor(self.idle_speed / 2)
       -- print("We halved")
    elseif r <= (chance_skip + chance_halve) then 
       -- print("We skipped")
        self.idle_speed = 0
        return true
    end

    return false
end

--(Function by Alrysc)
function highlight_tiles(self, list, time)
    local spell = Battle.Spell.new(self:get_team())


    local ref = self
    spell.update_func = function(self)
        for i=1, #list
        do 
            local t = list[i]
            if t and not t:is_edge() then 
                t:highlight(Highlight.Solid)
            end

        end


        time = time - 1
        if time == 0 then 
            self:delete()
        end

        if self.flinching then 
            if spell and not spell:is_deleted() then 
                spell:delete()
    
            end
        end
    end


    self:get_field():spawn(spell, self:get_current_tile())

    return spell
end

--(Function by Alrysc)
function move(self)
    if self.first_act then 
        
        self.anim:set_state("MOVE", {
            {duration=1, state="WARP_1"},
            {duration=1, state="WARP_2"},
            {duration=1, state="WARP_3"},
            {duration=1, state="WARP_4"},
            {duration=1, state="WARP_4"},
            {duration=1, state="WARP_3"},
            {duration=1, state="WARP_2"},
            {duration=1, state="WARP_1"},
        })

        self.prev_tile = self:get_current_tile()
        local tile = choose_move(self, self:get_field())
        if not tile then
            tile = self:get_current_tile()
        end
        self.next_tile = tile
        self.next_tile:reserve_entity_by_id(self:get_id())
        self.anim:on_frame(5, function()
            if self.can_move_to_func(self.next_tile) then 
            else
                self.next_tile = self:get_current_tile()
            end

            self:teleport(self.next_tile, ActionOrder.Voluntary, nil)
        end)

        self.anim:on_complete(function()
            -- Reset idle speed, since we did a real action
            self.idle_speed = self.base_idle_speed
            increment_pattern(self)
        end)

        self.first_act = false
    end
end

function choose_attack(self)
    local r = math.random(1,3)
    if      r == 1 then
        self.state = self.states.bakuen
    elseif  r == 2 then
        self.state = self.states.shuriken
    else
        local tile_selected = nil
        local enemy_tile = choose_enemy(self, self:get_field())
        local bunshin_tile = nil
        if enemy_tile then
            bunshin_tile = enemy_tile:get_tile(Direction.reverse(self:get_facing()), 1)
            if not check_obstacles(bunshin_tile, self) and bunshin_tile:is_walkable() then
                self.bunshin_tile = bunshin_tile
                tile_selected = true
            else
                tile_selected = false
            end
        else
            tile_selected = false
        end
        if tile_selected then
            self.state = self.states.kagebunshin
        else
            local r2 = math.random(1, 2)
            if      r == 1 then
                self.state = self.states.bakuen
            else
                self.state = self.states.shuriken
            end
        end
    end

    self.state.func(self)
    self.idle_speed = self.base_idle_speed * 2
end

function bakuen(self)
    if self.first_act then 
        self.anim:set_state("BAKUEN", {
            {duration=2, state="BAKUEN_1"},
            {duration=2, state="BAKUEN_2"},
            {duration=2, state="BAKUEN_3"},
            {duration=3, state="BAKUEN_4"},
            {duration=10, state="BAKUEN_4"},
            {duration=30, state="BAKUEN_4"},
        })

        self.anim:on_frame(1, function() --spawns 1 bunshin
            local field = self:get_field()
            local tiles = field:find_tiles(function(tile)
                return tile and tile:is_walkable() and tile:get_team() == self:get_team() and tile:y() ~= self:get_current_tile():y()
            end)
            if #tiles > 0 then
                local bunshin_tile = tiles[math.random(1,#tiles)]
                create_effect(self:get_facing(), SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", 0, -66, true, -9, self:get_field(), bunshin_tile)
                local bunshin = create_effect(self:get_facing(), SHADOWMAN_TEXTURE, SHADOWMAN_ANIMPATH, "BUNSHIN_BAKUEN", 0, 0, false, 0, field, bunshin_tile)
                bunshin:get_animation():on_frame(5, function()
                    spawn_bakuen(self, bunshin:get_tile(bunshin:get_facing(), 1))
                end)
                bunshin:get_animation():on_complete(function()
                    create_effect(self:get_facing(), SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", 0, -66, true, -9, self:get_field(), bunshin_tile)
                    bunshin:erase()
                end)
            end
        end)

        self.anim:on_frame(5, function() --creates bakuen
            spawn_bakuen(self, self:get_tile(self:get_facing(), 1))
        end)

        self.anim:on_complete(function()
            increment_pattern(self)
        end)

        self.first_act = false
    end
end

function shuriken(self)
    if self.first_act then 
        local frames = {}
        frames[1] = {duration=2, state="SHURIKEN_1"}
        frames[2] = {duration=2, state="SHURIKEN_2"}
        for i = 3, 13, 5 do
            frames[i] = {duration=1, state="SHURIKEN_3"}
        end
        for i = 4, 14, 5 do
            frames[i] = {duration=1, state="SHURIKEN_3"}
        end
        for i = 5, 15, 5 do
            frames[i] = {duration=2, state="SHURIKEN_4"}
        end
        for i = 6, 16, 5 do
            frames[i] = {duration=2, state="SHURIKEN_5"}
        end
        for i = 7, 12, 5 do
            frames[i] = {duration=8, state="SHURIKEN_6"}
        end
        frames[17] = {duration=30, state="SHURIKEN_6"}
        self.anim:set_state("SHURIKEN", frames)

        create_effect(self:get_facing(), SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", 0, -66, true, -9, self:get_field(), self:get_current_tile())
        self.anim:on_frame(1, function()
            self:toggle_hitbox(false)
        end)
        for i = 4, 9, 5 do
            self.anim:on_frame(i, function()
                local throw_tile = choose_enemy(self, self:get_field())
                if not throw_tile then
                    throw_tile = self:get_tile(self:get_facing(), 1)
                end
                spawn_shuriken(self, throw_tile, false)
            end)
        end
        self.anim:on_frame(14, function()
            local throw_tile = choose_enemy(self, self:get_field())
            if not throw_tile then
                throw_tile = self:get_tile(self:get_facing(), 1)
            end
            spawn_shuriken(self, throw_tile, true)
        end)

        self.anim:on_complete(function()
            self:toggle_hitbox(true)
            increment_pattern(self)
        end)

        self.first_act = false
    end
end

function sword_hitbox(user, tile)
    local team = user:get_team()
    local field = user:get_field()
    local facing = user:get_facing()

    local spell = Battle.Spell.new(team)
    spell:set_hit_props(
        HitProps.new(
            user.damage_kagebunshin,
            Hit.Impact | Hit.Flinch | Hit.Flash,
            Element.None,
            user:get_id(),
            Drag.None
        )
    )
    spell:set_facing(facing)
    local anim = spell:get_animation()
    anim:load(_folderpath.."attack.animation")
    anim:set_state("0")
    anim:on_complete(function()
		spell:erase()
	end)

    spell.on_spawn_func = function(self)
		--
    end
    spell.update_func = function(self)
        self:get_current_tile():attack_entities(self)
    end
    spell.attack_func = function(self, ent)
        if Battle.Obstacle.from(ent) == nil then
            --[[
            if Battle.Player.from(user) ~= nil then
                Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Low)
            end
            ]]
        else
            Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
        end
    end
    --[[
    spell.can_move_to_func = function(tile)
        return true
    end]]
    field:spawn(spell, tile)
end

function spawn_bakuen(user, tile)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end

        local team = user:get_team()
        local field = user:get_field()
        local facing = user:get_facing()

        local spell = Battle.Spell.new(team)
        spell:set_hit_props(
            HitProps.new(
                user.damage_bakuen, 
                Hit.Impact | Hit.Flinch | Hit.Flash, 
                Element.Fire, 
                user:get_id(), 
                Drag.None
            )
        )
        spell:set_facing(facing)
        local sprite = spell:sprite()
        sprite:set_texture(BAKUEN_TEXTURE)
        sprite:set_layer(-3)
        local animation = spell:get_animation()
        animation:load(BAKUEN_ANIMPATH)
        animation:set_state("0")
        animation:refresh(sprite)
        animation:on_frame(user.bakuen_frame, function()
            tile = tile:get_tile(facing, 1)
            spawn_next()
        end, true)
        animation:on_complete(function()
            spell:delete()
        end)
        local query_TeamHP = function(ent)
            if not user:is_team(ent:get_team()) and ent:get_health() > 0 then
                return true
            end
        end
        spell.on_spawn_func = function(self)
            Engine.play_audio(BAKUEN_AUDIO, AudioPriority.Low)
        end
        spell.update_func = function(self)
            local self_tile = self:get_current_tile()
            self_tile:attack_entities(self)
            self_tile:highlight(Highlight.Solid)
            if self_tile ~= nil and
                not self_tile:is_edge() and
                #self_tile:find_characters(query_TeamHP) <= 0 and 
                #self_tile:find_obstacles(query_TeamHP) <= 0 and 
                self_tile:get_state() == TileState.Grass
                then
                self_tile:set_state(TileState.Normal)
            end
            self:shake_camera(7, 0.025)
        end
        spell.attack_func = function(self, ent)
            create_effect(facing, EFFECT_TEXTURE, EFFECT_ANIMPATH, "2", math.random(-30,30), math.random(-50,-30), true, -999999, field, ent:get_current_tile())
            if Battle.Obstacle.from(ent) == nil then
                --[[
                if Battle.Player.from(user) ~= nil then
                    Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Low)
                end
                ]]
            else
                Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
            end
        end
        spell.battle_end_func = function(self)
            self:delete()
        end
        spell.delete_func = function(self)
            self:erase()
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end

function spawn_shuriken(user, tile, flashing)
    local team = user:get_team()
    local field = user:get_field()
    local facing = user:get_facing()

    local spell = Battle.Spell.new(team)
    if flashing then
        spell:set_hit_props(
            HitProps.new(
                user.damage_shuriken,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                Element.None,
                user:get_id(),
                Drag.None
            )
        )
    else
        spell:set_hit_props(
            HitProps.new(
                user.damage_shuriken,
                Hit.Impact | Hit.Flinch,
                Element.None,
                user:get_id(),
                Drag.None
            )
        )
    end
    spell:set_facing(facing)
    spell.falling = false
    spell.highlightning = true
    --spell.offset_x = (12*2)*7
    spell.offset_x = 72*2
    spell.offsetting_x = (12*2)
    if facing == Direction.Right then
        spell.offset_x = spell.offset_x *(-1)
        spell.offsetting_x = spell.offsetting_x *(-1)
    end
    --spell.offset_y = (12*2)*7 *(-1)
    spell.offset_y = (72*2) *(-1)
    spell.offsetting_y = (12*2) *(-1)
    spell:set_offset(spell.offset_x, spell.offset_y)
    local sprite = spell:sprite()
    sprite:set_texture(SHURIKEN_TEXTURE)
    sprite:set_layer(-3)
    local anim = spell:get_animation()
    anim:load(SHURIKEN_ANIMPATH)
    anim:set_state("0")
    anim:refresh(sprite)
    local do_once1 = true
    local do_once2 = true
    local do_once3 = true
    spell.on_spawn_func = function(self)
        Engine.play_audio(SHURIKEN_THROW_AUDIO, AudioPriority.Low)
    end
    spell.update_func = function(self)
        if self.highlightning then
            self:get_current_tile():highlight(Highlight.Solid)
        end
        if self.falling then
            self:set_offset(self:get_offset().x - self.offsetting_x, self:get_offset().y - self.offsetting_y)
        end
        if self:get_offset().y > 0 then
            if do_once2 then
                do_once2 = false
                self.falling = false
                spell:set_offset(0, 0)
                anim:set_state("1")
            end
        end
        if anim:get_state() == "0" then
            anim:on_frame(2, function()
                spell.falling = true
                if do_once1 then
                    do_once1 = false
                    local offx = 84*2
                    if facing == Direction.Right then
                        offx = offx *(-1)
                    end
                    create_effect(facing, SMOKE_TEXTURE, SMOKE_ANIMPATH, "1", offx, 84*2*-1, true, -9, field, self:get_current_tile())
                end
            end)
        end
        if anim:get_state() == "1" then
            anim:on_frame(1, function()
                self:get_current_tile():attack_entities(self)
                if do_once3 then
                    do_once3 = false
                    Engine.play_audio(SHURIKEN_HIT_AUDIO, AudioPriority.Low)
                end
            end)
            anim:on_frame(2, function()
                self.highlightning = false
            end)
            anim:on_complete(function()
                spell:erase()
            end)
        end
    end
    spell.attack_func = function(self, ent)
        if Battle.Obstacle.from(ent) == nil then
            --[[
            if Battle.Player.from(user) ~= nil then
                Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Low)
            end
            ]]
        else
            Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
        end
    end
    --[[
    spell.can_move_to_func = function(tile)
        return true
    end
    ]]
    field:spawn(spell, tile)
end

--(Function by Alrysc)
function find_valid_move_location(self)
	local target_tile
	local field = self:get_field()

	local tiles = field:find_tiles(function(tile)
		return self.can_move_to_func(tile)
	end)
  
	--print (#tiles)
	if #tiles >= 1 then
		target_tile = tiles[math.random(#tiles)]
	else
		target_tile = self:get_tile()
	end
	
	local start_tile = self:get_tile()
	if #tiles > 1 then
		while target_tile == start_tile do
		-- pick another, don't try to jump on the same tile if it's not necessary
		target_tile = tiles[math.random(#tiles)]
		end
	end
  
    return target_tile
end

function front_enemy_check(self)
    local facing = self:get_facing()
    local field = self:get_field()
    local team = self:get_team()

    local function query(c)
        return c:get_team() ~= team
    end

    for i = 1, 5, 1 do
        local target_tile = self:get_tile(facing, i)
        if target_tile ~= nil and #target_tile:find_characters(query) > 0 then
            --print("front TRUE")
            return true
        else
            --print("front FALSE")
            return false
        end
    end
end

function choose_enemy(self, field)
    local team = self:get_team()

    local target = field:find_characters(function(c)
        return c:get_team() ~= team
    end)

    if not target[1] then 
       -- print("No targets")
        return nil
    end

    t_x = target[1]:get_current_tile():x()
    t_y = target[1]:get_current_tile():y()

    local facing = -1
    if target[1]:get_facing() == Direction.Right then 
        facing = 1
    end

    local tile = field:tile_at(t_x, t_y)

    return tile
end

function choose_move(self, field)
    local team = self:get_team()

    local tiles = field:find_tiles(function(tile)
        return tile ~= self:get_current_tile() and self.can_move_to_func(tile)
    end)

    --print("Found ", #tiles, " possible tiles")

    if #tiles == 0 then 
        return self:get_current_tile()
    end

    return tiles[math.random(1, #tiles)]
end

function choose_move_to_enemy(self, field)
    local team = self:get_team()

    local enemy_tile = choose_enemy(self, field)
    local enemy_y = enemy_tile:y()

    local tiles = field:find_tiles(function(tile)
        return tile ~= self:get_current_tile() and self.can_move_to_func(tile) and tile:y() == enemy_y
    end)

    --print("Found ", #tiles, " possible tiles")

    if #tiles == 0 then 
        return self:get_current_tile()
    end

    return tiles[math.random(1, #tiles)]
end

function reconstruct_pattern(self)
    local pattern = {}
    local states = self.states
    local moves = self.move_count
    local r = math.random(1, 16)
    --print(r)
    if r <= self.chance_to_move_four_times then
        moves = 4
        --print("Two moves this time")
    elseif r > self.chance_to_move_four_times and r <= self.chance_to_move_five_times then
        moves = 5
        --print("Four moves this time")
    end

    for i=1, moves do
        table.insert(pattern, states.idle)
        table.insert(pattern, states.move)
    end
    table.insert(pattern, states.idle)
    table.insert(pattern, states.choose_attack)

    self.pattern = pattern
end

function increment_pattern(self)
   -- print("Pattern increment")

    self.first_act = true
    self.state_done = false
    self.pattern_index = self.pattern_index + 1
    if self.pattern_index > #self.pattern then
        self.random_attack = nil
        self.do_once1 = true
        self.bunshin_attack = false
        reconstruct_pattern(self)
 --       print("Reconstructed pattern")
        self.pattern_index = 1
    end

    local next_state = self.pattern[self.pattern_index]
    self.state = next_state
  --  print("Moving to state named ", next_state.name)

    if next_state == self.states.start_sub_pattern then 
        self.in_sub_pattern = true
        increment_pattern(self)
    end

    if next_state == self.states.finish_sub_pattern then 
        self.in_sub_pattern = false
        increment_pattern(self)

    end

   -- print("Changing to "..self.pattern_index..", which is "..self.pattern[self.pattern_index].name)

end

function check_obstacles(tile, self)
    local ob = tile:find_obstacles(function(o)
        return o:get_health() > 0 
    end)

    return #ob > 0 
end

function check_characters(tile, self)
    local characters = tile:find_characters(function(c)
        return c:get_id() ~= self:get_id() and c:get_team() ~= self:get_team()
    end)

    return #characters > 0
end

function check_characters_true(tile, self)
    local characters = tile:find_characters(function(c)
        return true
    end)

    return #characters > 0
end

function create_effect(effect_facing, effect_texture, effect_animpath, effect_state, offset_x, offset_y, flip, offset_layer, field, tile)
    local hitfx = Battle.Artifact.new()
    hitfx:set_facing(effect_facing)
    hitfx:set_texture(effect_texture, true)
    hitfx:set_offset(offset_x, offset_y)
    hitfx:never_flip(flip)
    local hitfx_sprite = hitfx:sprite()
    hitfx_sprite:set_layer(offset_layer)
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