local battle_helpers = include("battle_helpers.lua")
local character_info = {name = "AirMan", hp = 1000,height=80}
local character_animation = _modpath.."battle.animation"
--local shockwave_spawn = 3
local anim_speed = 1
local blast_sfx = Engine.load_audio(_folderpath .. "blast.ogg")
local wind_sfx = Engine.load_audio(_folderpath .. "wind.ogg")
local wind2_sfx = Engine.load_audio(_folderpath .. "wind2.ogg")
local blast_texture = Engine.load_texture(_folderpath .. "blast.png")
local tornado_animation = _modpath.."tornado.animation"
local tornado_texture = Engine.load_texture(_modpath.."tornado.png")
local bigtornado_animation = _modpath.."bigtornado.animation"
local bigtornado_texture = Engine.load_texture(_modpath.."bigtornado.png")
--local hit_sfx = Engine.load_audio(_modpath.."hitsound.ogg")


local CHARACTER_TEXTURE = Engine.load_texture(_modpath .. "battle.png")
local move_counter = 0
local base_damage = 0

function package_init(self)

    -- Required function, main package information

    -- Load character resources
	move_counter = 0
    local base_animation_path = character_animation
	self:set_texture(CHARACTER_TEXTURE, true)
    self.animation = self:get_animation()
    self.animation:load(base_animation_path)
	self.animation:set_playback_speed(anim_speed)

    -- Load extra resources

    -- Set up character meta
    self:set_name(character_info.name)
    self:set_height(character_info.height)
    local max_health
    if(self:get_rank()==Rank.V1) then 
        max_health = 1000 
        base_damage = 70
        self.frames_between_actions= 30
    elseif self:get_rank()==Rank.V2 
    then max_health=1500
        base_damage=90
        self.frames_between_actions= 25
    else 
        max_health=2000
        base_damage=150
        self.frames_between_actions= 20
    end
    self:set_health(max_health)
    self.max_health = max_health
    self:share_tile(false)
    self:set_explosion_behavior(4, 1, false)
    self:set_offset(0, 0)
    self:set_element(Element.Elec)
	self.animation:set_state("IDLE")
    self.cascade_frame_index = 5 --lower = faster shockwaves
    self.ai_wait = self.frames_between_actions
    self.ai_taken_turn = false
	self.wait_time = 0
	self.steps = 0
    self.selected_spell = 1
    self.state = "normal"
    self.max_spells = 5
    self.fans = 0
    self.spells = {action_blast, action_blast, action_tornado3, action_bigtornado, fan_form}

    -- Initial state

	self.update_func = function ()
		self.wait_time = self.wait_time + 1
		if self.wait_time < self.ai_wait then
		  return
		end
        if(self.state == "normal") then
		move(self)
        elseif(self.state == "fanform") then
            if(self.fans>0) then
            fan(self)
            else
            self.state="normal"
            self.wait_time=0
            self.steps = 0
            end
        return
        end
		self.steps = self.steps + 1
		
		if self.steps == 4 then
            local randomSpellId = math.random(self.max_spells)
            self.spells[randomSpellId](self)
		end
        if(self.steps>6) then
            self.steps=0
        end
		self.wait_time=0
	end
end

function move(self)

	move_counter = move_counter + 1

	local anim = self:get_animation()
	--anim:set_state("WARP_2")
	battle_helpers.move_at_random(self)
	anim:on_complete(function()
	
		anim:set_state("WARP_2")
		anim:on_complete(function()
				self.wait_time=0
		end)

	end)
end

function action_blast(character)
	local facing = character:get_facing()
    local action = Battle.CardAction.new(character, "ATTACK_1")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        self:add_anim_action(8,function ()
            character:toggle_counter(true)
			Engine.play_audio(wind_sfx, AudioPriority.Highest)
        end)
        self:add_anim_action(10,function ()
            spawn_blast(character)
        end)
        self:add_anim_action(12,function ()
            character:toggle_counter(false)
			character.steps=0
			character.animation:set_state("IDLE")
        end)
    
   end
    character:card_action_event(action, ActionOrder.Voluntary)
end

function get_enemy_tiles(field)
    local tiles_array = {}
    table.insert(tiles_array,field:tile_at(1,1))
    table.insert(tiles_array,field:tile_at(1,2))
    table.insert(tiles_array,field:tile_at(1,3))
    table.insert(tiles_array,field:tile_at(2,1))
    table.insert(tiles_array,field:tile_at(2,3))
    table.insert(tiles_array,field:tile_at(3,1))
    table.insert(tiles_array,field:tile_at(3,2))
    table.insert(tiles_array,field:tile_at(3,3))
    return tiles_array
end

function action_bigtornado(character)
    local action = Battle.CardAction.new(character, "PUSH_ATTACK")
    local tornado1 = nil
    local tornado2 = nil
    local available_tiles = get_enemy_tiles(character:get_field())
    shuffle(available_tiles)
    --highlight tiles for a bit before they show up
    local previewHighlight = function(tile, frames)
        local highlightSpell = Battle.Spell.new(character:get_team())
        highlightSpell.frames = frames
        character:get_field():spawn(highlightSpell, tile)
        highlightSpell.update_func = function ()
            if(highlightSpell.frames>0) then
                tile:highlight(Highlight.Flash)
            end
            highlightSpell.frames = highlightSpell.frames-1
            if(highlightSpell.frames==0) then
                highlightSpell:erase()
            end
        end
    end

    previewHighlight(available_tiles[1], 30)
    previewHighlight(available_tiles[2], 30)

	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        self:add_anim_action(1,function ()
            character:toggle_counter(true)
			Engine.play_audio(wind_sfx, AudioPriority.Highest)
            
        end)
        self:add_anim_action(6,function ()
            character:toggle_counter(false)
            available_tiles[1]:highlight(Highlight.Flash)
            available_tiles[2]:highlight(Highlight.Flash)
            tornado1 = create_bigtornado(character, available_tiles[1], 50, 15)
            tornado2 = create_bigtornado(character, available_tiles[2], 50, 15)
            tornado1.wait_frames=0
            tornado2.wait_frames=0
        end)
        self:add_anim_action(7,function ()
			character.steps=0
			character.animation:set_state("IDLE")
        end)
    
   end
    character:card_action_event(action, ActionOrder.Voluntary)   
end

--move to be used on low health.
function fan_form(owner)
    if((owner:get_health()>owner.max_health/2)) then
        action_blast(owner)  --just redirect to this move
        return
    end
    local anim = owner:get_animation()
    anim:set_state("FAN_FORM")
    owner.state = "fanform"
    anim:set_playback(Playback.Loop)
    owner.fans=20
    Engine.play_audio(wind2_sfx, AudioPriority.Highest)
end

function fan(character)
    local field = character:get_field()
    local tornado1 = create_tornado(character, field:tile_at(6, math.random(3), character:get_facing()), 50, 8, character:get_facing(), "big")

    tornado1.wait_frames=0
    character.wait_time=character.frames_between_actions/2
    character.fans = character.fans-1
end


function spawn_blast(owner)
    local owner_id = owner:get_id()
    local team = owner:get_team()
    local field = owner:get_field()
	local tile = owner:get_tile(Direction.Left,1)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then 
            return end

        Engine.play_audio(blast_sfx, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(owner:get_facing())
        spell:highlight_tile(Highlight.Solid)
        spell:set_hit_props(HitProps.new(base_damage, Hit.Flash | Hit.Flinch, Element.Wind, owner_id, Drag.new()))

        local sprite = spell:sprite()
        sprite:set_texture(blast_texture)
        spell:set_offset(0,-50)

        local animation = spell:get_animation()
        animation:load(_folderpath .. "blast.animation")
        local animationState = "Default"
        if(owner:get_rank()==Rank.SP) then
            animationState="Fast"
        end
        animation:set_state(animationState)
        animation:refresh(sprite)

        animation:on_frame(2, function()
            tile = getNextTile(owner:get_facing(), spell)
        end)
        animation:on_frame(4, function()
            
            spawn_next()
        end, true)
        animation:on_complete(function() 
            spell:erase() 
            
        end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end

function action_tornado3(character)
    local action = Battle.CardAction.new(character, "PUSH_ATTACK")
    local tornado1 = nil
    local tornado2 = nil
    local tornado3 = nil
    local speeds = {8, 14, 20}
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        self:add_anim_action(2,function ()
            character:toggle_counter(true)
			Engine.play_audio(wind_sfx, AudioPriority.Highest)
            local x = user:get_tile(user:get_facing(), 1):x()
            local field = user:get_field()
            shuffle(speeds)
            tornado1 = create_tornado(character, field:tile_at(6, 1), 50, speeds[1], user:get_facing())
            tornado2 = create_tornado(character, field:tile_at(6, 2), 50, speeds[2],user:get_facing())
            tornado3 = create_tornado(character, field:tile_at(6, 3), 50, speeds[3],user:get_facing())
            character.steps=0
			
        end)
        self:add_anim_action(7,function ()
            character:toggle_counter(false)
            character.animation:set_state("IDLE")   
        end)
    
   end
    character:card_action_event(action, ActionOrder.Voluntary)   
end

function create_tornado(user, tile, damage, speed, direction, size)

    local texture = tornado_texture
    local animationFile = tornado_animation
    if(size) then
        texture =  bigtornado_texture
        animationFile = bigtornado_animation
        damage= base_damage*2
    end
    local spell = Battle.Spell.new(user:get_team())
    spell.wait_frames = 40
    spell:set_facing(direction)
    spell:set_hit_props(
        HitProps.new(
            damage, 
            Hit.Impact | Hit.Flash | Hit.Flinch, 
            Element.Wind, 
            user:get_id(), 
            Drag.None
        )
    )
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    sprite:set_layer(-1)
    local anim = spell:get_animation()
    anim:load(animationFile)
    anim:set_state("1")
    anim:set_playback(Playback.Loop)
    anim:refresh(sprite)

    spell.update_func = function(self, dt)
        if(spell.wait_frames<=0) then
            local tile = spell:get_tile(direction, 1)
            if(tile == nil) then
                spell:erase()
                return
            end
            spell:slide(tile, frames(speed), frames(0), ActionOrder.Voluntary, nil)
        else
            spell.wait_frames=spell.wait_frames-1
        end
        self:get_current_tile():attack_entities(self)
    end

    spell.attack_func = function(self, other) 
        --Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Highest)
    end
    spell.delete_func = function(self)
        spell:erase()
    end
    spell.battle_end_func = function(self)
		spell:erase()
	end
    spell.can_move_to_func = function(tile)
        return true
    end
    user:get_field():spawn(spell, tile:x(), tile:y())
    return spell
end

--bigtornado create
function create_bigtornado(user, tile, damage, speed)
    local target = find_target(user)
    local dir = Direction.Up
    if (tile:y() < target:get_tile():y()) then
        dir = Direction.Down
    elseif(tile:y()>target:get_tile():y()) then
        dir = Direction.Up
    elseif(tile:x()<target:get_tile():x()) then
        dir = Direction.Right
    else
        dir = Direction.Left
    end
    return create_tornado(user, tile, damage, speed, dir, "big")
end


function find_target(self)
    local field = self:get_field()
    local team = self:get_team()
    local target_list = field:find_characters(function(other_character)
        return other_character:get_team() ~= team
    end)
    if #target_list == 0 then
        return
    end
    local target_character = target_list[1]
    return target_character
end

--shuffle function to provide some randomness 
function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end

function getNextTile(direction, spell) 
    local tile = spell:get_current_tile():get_tile(Direction.Left, 1)
    return tile;
end