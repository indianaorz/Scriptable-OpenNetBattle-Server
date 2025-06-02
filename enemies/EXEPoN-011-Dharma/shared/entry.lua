local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."EXE4_270.ogg")
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."EXE4_221.ogg")
local EFFECT_TEXTURE = Engine.load_texture(_folderpath.."effect.png")
local EFFECT_ANIMPATH = _folderpath.."effect.animation"

local CHARACTER_ANIMATION = _folderpath.."battle.animation"
local CHARACTER_TEXTURE = Engine.load_texture(_folderpath.."battle.grayscaled.png")

local PUCK_TEXTURE = Engine.load_texture(_folderpath.."puck.png")
local PUCK_ANIMPATH = _folderpath.."puck.animation"
local MOB_MOVE_TEXTURE = Engine.load_texture(_folderpath.."mob_move.png")
local MOB_MOVE_ANIMPATH = _folderpath.."mob_move.animation"
local LAUNCH_AUDIO = Engine.load_audio(_folderpath.."EXE4_169.ogg")
local BOUNCE_AUDIO = Engine.load_audio(_folderpath.."EXE4_180.ogg")

--possible states for character
local states = { MOVE = 1, SHOOT = 2 }
local debug = false

function debug_print(str)
    if debug then
        print("[Dharma] "..str)
    end
end

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
    self.damage = character_info.damage
    self.element = Element.None
    self:set_element(self.element)
    self:share_tile(false)
    self:set_explosion_behavior(3, 1, false)
    self:set_offset(0, 0)
    self:set_palette(Engine.load_texture(character_info.palette))
    self.animation:set_state("IDLE")
    self.frame_counter = 0
    self.started = false
    self.idle_frames = 8
    self.move_speed = character_info.move_speed
    self.move_time = character_info.move_time
    --self.move_tiles = character_info.move_tiles
    self.puck_speed = character_info.puck_speed
    --self.defense = Battle.DefenseVirusBody.new()
    --self:add_defense_rule(self.defense)
    self.has_attacked_once = false

    local direction_table = {Direction.Up, Direction.Down, Direction.Left, Direction.Right}
    local random_move_direction = Direction.None
    local new_direction = Direction.None
    local has_picked_direction = false
    --[[
    self.action_idle = function(frame)
        if (frame == self.idle_frames) then
            --choose move direction
            self.animation:set_state("IDLE")
            self.animation:set_playback(Playback.Loop)
            self.set_state(states.MOVE)
        end
    end
    ]]
    self.can_move_to_func = function(tile)
        return self:is_team(tile:get_team()) and tile:is_walkable() and not tile:is_edge() and not tile:is_reserved({self:get_id()})
    end
    self.action_move = function(frame)
        if frame >= self.move_time and not self:is_sliding() then
            if self.wait_tiles == 0 then
                --once has moved enough tiles, attack
                self.set_state(states.SHOOT)
                if self:get_rank() == Rank.V3 or self:get_rank() == Rank.SP then
                    self.wait_tiles = math.random(1, 3)
                else
                    self.wait_tiles = math.random(2, 4)
                end
            else
                self.wait_tiles = self.wait_tiles - 1
                self.set_state(states.MOVE)
            end
        else
            local field = self:get_field()
            if not self:is_sliding() then
                if not has_picked_direction then
                    random_move_direction = direction_table[math.random(1, #direction_table)]
                    local next_tile = self:get_tile(random_move_direction, 1)
                    if self.can_move_to_func(next_tile) and is_tile_free_for_movement(next_tile, self) then
                        next_tile:reserve_entity_by_id(self:get_id())
                        has_picked_direction = true
                    else
                        new_direction = Direction.flip_x(random_move_direction)
                        next_tile = self:get_tile(new_direction, 1)
                        if self.can_move_to_func(next_tile) and is_tile_free_for_movement(next_tile, self) then
                            next_tile:reserve_entity_by_id(self:get_id())
                            has_picked_direction = true
                            random_move_direction = new_direction
                        else
                            new_direction = Direction.flip_y(random_move_direction)
                            next_tile = self:get_tile(new_direction, 1)
                            if self.can_move_to_func(next_tile) and is_tile_free_for_movement(next_tile, self) then
                                next_tile:reserve_entity_by_id(self:get_id())
                                has_picked_direction = true
                                random_move_direction = new_direction
                            else
                                new_direction = Direction.reverse(random_move_direction)
                                next_tile = self:get_tile(new_direction, 1)
                                if self.can_move_to_func(next_tile) and is_tile_free_for_movement(next_tile, self) then
                                    next_tile:reserve_entity_by_id(self:get_id())
                                    has_picked_direction = true
                                    random_move_direction = new_direction
                                end
                            end
                        end
                    end
                else
                    self:slide(self:get_tile(random_move_direction, 1), frames(self.move_speed), frames(0), ActionOrder.Immediate, function()
                        --self.move_tiles = self.move_tiles - 1
                    end)
                    has_picked_direction = false
                end
            end
        end
    end

    self.action_shoot = function(frame)
        if frame == 1 then
            self.has_attacked_once = true
            self.animation:set_state("ATTACK")

            self.animation:on_frame(9, function()
                create_puck(self, self:get_current_tile())
            end)
            self.animation:on_complete(function()
                self.set_state(states.MOVE)
            end)
        end
    end

    self.set_state = function(state)
        self.state = state
        self.frame_counter = 0
    end

    local actions = { [1] = self.action_move, [2] = self.action_shoot }

    self.update_func = function()
        self.frame_counter = self.frame_counter + 1
        if not self.started then
            --This runs once the battle is started
            self.started = true
            if self:get_rank() == Rank.V3 or self:get_rank() == Rank.SP then
                self.wait_tiles = math.random(1, 3)
            else
                self.wait_tiles = math.random(2, 4)
            end
            self.set_state(states.MOVE)
        else
            --On every frame, we will call the state action func.
            local action_func = actions[self.state]
            action_func(self.frame_counter)
        end
    end

    

end

function create_puck(user, tile)
    local team = user:get_team()
    local field = user:get_field()
    local facing = user:get_facing()

    local spell = Battle.Spell.new(team)
    local direction = facing
    local puck_speed = user.puck_speed

    local anim = spell:get_animation()
    anim:load(PUCK_ANIMPATH)
    anim:set_state("0")
    local sprite = spell:sprite()
    sprite:set_texture(PUCK_TEXTURE)
    anim:refresh(sprite)
    anim:set_playback(Playback.Loop)

    spell:highlight_tile(Highlight.Solid)

    spell:set_hit_props(
        HitProps.new(
            user.damage, 
            Hit.Impact | Hit.Flinch | Hit.Breaking,
            Element.None,
            user:get_id(),
            Drag.None
        )
    )
    spell.bounce_once = true

    spell.update_func = function(self, dt) 
    	local tile = self:get_current_tile()
        tile:attack_entities(self)

		if tile:is_edge() or tile:is_hole() then
			self:delete()
		end

        if not self:is_sliding() then
            local dest
        	local play_bounce
            dest, play_bounce, direction = Bounce(tile, spell, direction, team)
            if dest then
	            self:slide(dest, frames(puck_speed), frames(0), ActionOrder.Voluntary, nil)
	            if play_bounce then
                    spell.bounce_once = false
	            	Engine.play_audio(BOUNCE_AUDIO, AudioPriority.Low)
	            end
	        else
	        	self:delete()
	        end
        end
    end

	spell.collision_func = function(self, other)
	end

    spell.attack_func = function(self, ent)
		create_effect(facing, EFFECT_TEXTURE, EFFECT_ANIMPATH, "1", math.random(-30,30), math.random(-50,-30), true, -999999, field, ent:get_current_tile())
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

    spell.delete_func = function(self)
		if not self:get_current_tile():is_edge() then
			--if we're not on an edge tile, which happens mostly at the end of battle for some reason,
			--then spawn a mob move to visually vanish the puck when it deletes.
			--presentation!
			create_effect(facing, MOB_MOVE_TEXTURE, MOB_MOVE_ANIMPATH, "DEFAULT", 0, 0, true, -9, field, self:get_current_tile())
		end
		self:erase()
    end

    spell.can_move_to_func = function(tile)
		--if tile:is_edge() or tile:is_hole() then
        --[[
		if tile:is_edge() then
			return false
		end
        ]]
		return true
    end

    spell.battle_end_func = function(tile)
        self:delete()
    end

	Engine.play_audio(LAUNCH_AUDIO, AudioPriority.Low)
	Engine.play_audio(BOUNCE_AUDIO, AudioPriority.Low)

	field:spawn(spell, tile)

    return spell
end

function Bounce(tile, spell, direction, self_team)
	local play_bounce = true
    local new_dir = direction
    local tile_team = tile:get_team()	-- this is the team of the tile we're currently on

    -- no entry if the target tile is friendly and we aren't currently on a friendly tile
    --[[
    local function teamcheck(new_tile)
    	local new_tile_team = new_tile:get_team()
	    if (new_tile_team == self_team) and not (new_tile_team == tile_team) then
	    	return true
	    end
	    return false
    end
    ]]
    local function edgecheck(new_tile)
	    if new_tile:is_edge() and spell.bounce_once then
	    	return true
	    end
	    return false
    end
    -- wraps up all the checks into one function and returns true if we can't move to the tile
    local function bad()
    	local new_tile = tile:get_tile(new_dir, 1)
    	if edgecheck(new_tile) then return true end
    	return not spell.can_move_to_func(new_tile)
    end

    -- check if any tile is accessible, 1) no flip, 2) flip x, 3) flip y, 4) flip x and y
    -- (there's no reason to check x before y, it's arbitrary, but the order matters for the other ones)
    if bad() then
	    new_dir = Direction.flip_x(direction)
	    if bad() then
		    new_dir = Direction.flip_y(direction)
		    if bad() then
			    new_dir = Direction.reverse(direction)
			    if bad() then
			    	-- by returning false, we nil some expected returns, but it's ok cuz the puck will die immediately
			    	return false
			    end
			end
	    end
	else
		play_bounce = false
    end

    direction = new_dir
    local dest = tile:get_tile(direction, 1)
	return dest, play_bounce, direction
end

function get_free_direction(tile, direction1, direction2)
    if (not tile:get_tile(direction1, 1):is_edge()) then
        return direction1
    else
        return direction2
    end
end

function is_tile_free_for_movement(tile, character)
    --Basic check to see if a tile is suitable for a chracter of a team to move to

    if tile:get_team() ~= character:get_team() or tile:is_reserved({ character:get_id(), character._reserver }) then
        return false
    end
    if tile:is_edge() or not tile:is_walkable() then
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

return package_init