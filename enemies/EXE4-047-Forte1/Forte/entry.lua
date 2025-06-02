local print_debug = false

local AUDIO_DAMAGE_PLAYER = Engine.load_audio(_folderpath.."sfx/EXE4_219.ogg", true)
local AUDIO_DAMAGE_ENEMY = Engine.load_audio(_folderpath.."sfx/EXE4_270.ogg", true)
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."sfx/EXE4_221.ogg", true)

local FORTE_TEXTURE = nil
local FORTE_PALETTE = nil
local FORTE_ANIMPATH = _folderpath.."gfx/forte.animation"
local FORTE_MOVE_TEXTURE = nil
local FORTE_MOVE_PALETTE = nil
local FORTE_MOVE2_TEXTURE = Engine.load_texture(_folderpath.."gfx/move2.grayscaled.png")
local FORTE_MOVE2_ANIMPATH = _folderpath.."gfx/forte2.animation"

local SHOOTINGBUSTER_TEXTURE = Engine.load_texture(_folderpath.."gfx/shootingbuster.png")
local SHOOTINGBUSTER_ANIMPATH = _folderpath.."gfx/shootingbuster.animation"
local DARKARMBLADE1_TEXTURE = Engine.load_texture(_folderpath.."gfx/darkarmblade1.png")
local DARKARMBLADE1_ANIMPATH = _folderpath.."gfx/darkarmblade1.animation"
local DARKARMBLADE2_TEXTURE = Engine.load_texture(_folderpath.."gfx/darkarmblade2.png")
local DARKARMBLADE2_ANIMPATH = _folderpath.."gfx/darkarmblade2.animation"
local ORBS_TEXTURE = Engine.load_texture(_folderpath.."gfx/orbs.png")
local ORBS_ANIMPATH = _folderpath.."gfx/orbs.animation"
local HELLSROLLING_TEXTURE = Engine.load_texture(_folderpath.."gfx/hellsrolling.png")
local HELLSROLLING_ANIMPATH = _folderpath.."gfx/hellsrolling.animation"
local DARKNESSOVERLOAD_TEXTURE = Engine.load_texture(_folderpath.."gfx/darknessoverload.png")
local DARKNESSOVERLOAD_ANIMPATH = _folderpath.."gfx/darknessoverload.animation"

local VULCAN_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE4_200.ogg", true)
local DARKARMBLADE_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE4_6.ogg", true)
local ORBS_AUDIO = Engine.load_audio(_folderpath.."sfx/forteorbs.ogg", true)
local HELLSROLLING_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE4_338.ogg", true)
local DARKNESSOVERLOAD_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE4_343.ogg", true)

local BLACKBARRIER_TEXTURE = Engine.load_texture(_folderpath.."gfx/blackbarrier.png")
local BLACKBARRIER_ANIMPATH = _folderpath.."gfx/blackbarrier.animation"
local BLACKBARRIER_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE4_261.ogg", true)

local EFFECT_TEXTURE = Engine.load_texture(_folderpath.."gfx/effect.png")
local EFFECT_ANIMPATH = _folderpath.."gfx/effect.animation"

local function debug_print(text)
    if print_debug then
        print("[Forte] "..text)
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

local function create_hitbox(user, tile, type)
    local hitbox = graphic_init("spell", 0, 0, false, false, false, false, false, user, user:get_facing())
    if type == "SHOOTINGBUSTER" then
        hitbox:set_hit_props(
            HitProps.new(
                user.damage_shootingbuster,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                Element.None,
                user:get_context(),
                Drag.None
            )
        )
    elseif type == "DARKARMBLADE" then
        hitbox:set_hit_props(
            HitProps.new(
                user.damage_darkarmblade,
                Hit.Impact | Hit.Flinch | Hit.Flash,
                Element.Sword,
                user:get_context(),
                Drag.None
            )
        )
    elseif type == "DARKNESSOVERLOAD" then
        hitbox:set_hit_props(
            HitProps.new(
                user.damage_darknessoverload,
                Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking | Hit.Pierce | Hit.Retangible,
                Element.None,
                user:get_context(),
                Drag.None
            )
        )
    end
    hitbox.on_spawn_func = function(self)
        if type == "DARKNESSOVERLOAD" and not tile:is_hole() and not tile:is_cracked() then
            Engine.play_audio(AudioType.PanelCrack, AudioPriority.Low)
            tile:set_state(TileState.Cracked)
        end
    end
    hitbox.update_func = function(self)
        self:get_tile():attack_entities(self)
        self:erase()
    end
    hitbox.attack_func = function(self, other)
        if Battle.Obstacle.from(other) == nil then
            Engine.play_audio(AudioType.Hurt, AudioPriority.Low)
		else
			Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
		end
    end
    user:get_field():spawn(hitbox, tile)
    return hitbox
end

local function create_shootingbuster(user, tile)
    local impact = graphic_init("artifact", 0, 0, SHOOTINGBUSTER_TEXTURE, SHOOTINGBUSTER_ANIMPATH, "0", Playback.Once, -3, user, user:get_facing())
    impact.wait_frames = 0
    impact.do_once = true
    impact.update_func = function(self)
        if self.wait_frames < 20 then
            self.wait_frames = self.wait_frames + 1
            tile:highlight(Highlight.Flash)
        else
            if self.do_once then
                self.do_once = false
                self:get_animation():set_state("1")
                self:get_animation():refresh(self:sprite())
                create_hitbox(user, tile, "SHOOTINGBUSTER")
                Engine.play_audio(VULCAN_AUDIO, AudioPriority.Low)
            end
        end
        if self:get_animation():get_state() == "1" then
            self:get_animation():on_complete(function()
                self:erase()
            end)
        end
    end
    user:get_field():spawn(impact, tile)
    return impact
end

local function shootingbuster_spawner(user, tile)
    local spawner = graphic_init("spell", 0, 0, false, false, false, false, false, user, user:get_facing())
    spawner.frames = 0
    spawner.update_func = function(self)
        self.frames = self.frames + 1
    end
    user:get_field():spawn(impact, tile)
    return spawner
end

local function create_darkarmblade1(user, tile)
    local darkarmblade = graphic_init("artifact", 0, 0, DARKARMBLADE1_TEXTURE, DARKARMBLADE1_ANIMPATH, "0", Playback.Once, -3, user, user:get_facing())
    darkarmblade:get_animation():on_complete(function()
        darkarmblade:erase()
    end)
    darkarmblade.on_spawn_func = function()
        Engine.play_audio(DARKARMBLADE_AUDIO, AudioPriority.Low)
    end
    user:get_field():spawn(darkarmblade, tile)
    create_hitbox(user, tile, "DARKARMBLADE")
    create_hitbox(user, tile:get_tile(darkarmblade:get_facing(), 1), "DARKARMBLADE")
    return darkarmblade
end

local function create_darkarmblade2(user, tile, second)
    local darkarmblade = graphic_init("artifact", 0, 0, DARKARMBLADE2_TEXTURE, DARKARMBLADE2_ANIMPATH, "0", Playback.Once, -3, user, user:get_facing())
    darkarmblade:get_animation():on_complete(function()
        darkarmblade:erase()
    end)
    darkarmblade.on_spawn_func = function()
        Engine.play_audio(DARKARMBLADE_AUDIO, AudioPriority.Low)
    end
    user:get_field():spawn(darkarmblade, tile)
    create_hitbox(user, tile, "DARKARMBLADE")
    create_hitbox(user, tile:get_tile(Direction.Up, 1), "DARKARMBLADE")
    create_hitbox(user, tile:get_tile(Direction.Down, 1), "DARKARMBLADE")
    return darkarmblade
end

local function create_hellsrolling(user, tile, type)
    local x_coord = 24
    local y_coord = 0
    if user:get_facing() == Direction.Left then x_coord = -x_coord end
    local hellsrolling = graphic_init("spell", x_coord*2, y_coord, HELLSROLLING_TEXTURE, HELLSROLLING_ANIMPATH, "0", Playback.Loop, -3, user, user:get_facing())
    hellsrolling:set_hit_props(
        HitProps.new(
            user.damage_hellsrolling,
            Hit.Impact | Hit.Flinch | Hit.Flash,
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
    hellsrolling.x_coord = x_coord
    hellsrolling.y_coord = y_coord
    hellsrolling.mult_x = 0
    hellsrolling.mult_y = 0
    hellsrolling.frames = 0
    hellsrolling.can_move = 0
    hellsrolling.move_state = 0
    local round = function(val)
        if facing == Direction.Right then
            return math.floor(val)
        else
            return math.ceil(val)
        end
    end
    local tileWidth = tile:width()/4
    local tileHeight = tile:height()/4
    local enemy_query = function(other)
        return other and not other:is_team(user:get_team()) and other:get_health() > 0
    end
    hellsrolling.on_spawn_func = function()
        Engine.play_audio(HELLSROLLING_AUDIO, AudioPriority.Low)
    end
    hellsrolling.update_func = function(self)
        self:get_tile():attack_entities(self)
        --self:highlight_tile(Highlight.Solid)
        if self.can_move ~= 3 then
            self.x_coord = self.x_coord + self.mult_x
            self.y_coord = self.y_coord + self.mult_y
        end
        if self.can_move == 0 then
            self.frames = self.frames + 1
            if self.frames == 7 then
                self.move_state = 1
            elseif self.frames == 10 then
                self.move_state = 2
            elseif self.frames == 14 then
                self.move_state = 3
            elseif self.frames == 17 then
                self.move_state = 4
            elseif self.frames == 22 then
                self.move_state = 5
            elseif self.frames == 25 then
                self.move_state = 6
            elseif self.frames == 30 then
                self.move_state = 7
            elseif self.frames > 30 then
                self.can_move = 1
            end
            if self.frames <= 30 then
                if type == "1" then
                    self.mult_y = -1
                elseif type == "2" then
                    self.mult_y = 1
                end
            else
                self.mult_y = 0
            end
            if self.move_state == 0 then
                self.mult_x = -3
            elseif self.move_state == 1 then
                self.mult_x = -2
            elseif self.move_state == 2 then
                self.mult_x = -1
            elseif self.move_state == 3 then
                self.mult_x = 0
            elseif self.move_state == 4 then
                self.mult_x = 1
            elseif self.move_state == 5 then
                self.mult_x = 2
            elseif self.move_state == 6 then
                self.mult_x = 3
            elseif self.move_state == 7 then
                self.mult_x = 4
            end
            if self:get_facing() == Direction.Left then self.mult_x = -self.mult_x end
        end
        if self.can_move == 0 then
            if type == "1" then
                if self.y_coord <= -tileHeight then
                    self:teleport(self:get_tile(Direction.Up, 1), ActionOrder.Immediate)
                    self.y_coord = tileHeight
                end
            elseif type == "2" then
                if self.y_coord >= tileHeight then
                    self:teleport(self:get_tile(Direction.Down, 1), ActionOrder.Immediate)
                    self.y_coord = -tileHeight
                end
            end
            self:set_offset(self.x_coord*2, self.y_coord*2)
        elseif self.can_move == 1 then
            if round(self.x_coord) > -2 and round(self.x_coord) < 2 then
                if self:get_tile():get_team() ~= self:get_team() then
                    if (#self:get_tile(Direction.join(self:get_facing(), Direction.Up), 1):find_characters(enemy_query) > 0) or (#self:get_tile(Direction.join(self:get_facing(), Direction.Down), 1):find_characters(enemy_query) > 0) then
                        self.x_coord = 0
                        self.can_move = 2
                    end
                end
            end
            if self:get_facing() == Direction.Right and round(self.x_coord) >= tileWidth then
                if self:get_tile(Direction.Right, 1):is_hole() then
                    self:get_animation():set_state("1")
                    self:get_animation():refresh(self:sprite())
                    self.can_move = 3
                else
                    self:teleport(self:get_tile(Direction.Right, 1), ActionOrder.Immediate)
                    self.x_coord = -tileWidth
                end
            elseif self:get_facing() == Direction.Left and round(self.x_coord) <= -tileWidth then
                if self:get_tile(Direction.Left, 1):is_hole() then
                    self:get_animation():set_state("1")
                    self:get_animation():refresh(self:sprite())
                    self.can_move = 3
                else
                    self:teleport(self:get_tile(Direction.Left, 1), ActionOrder.Immediate)
                    self.x_coord = tileWidth
                end
            end
            self.y_coord = 0
            self:set_offset(self.x_coord*2, self.y_coord*2)
        elseif self.can_move == 2 then
            self.mult_x = (round(tileWidth*2/8))
            if self:get_facing() == Direction.Left then self.mult_x = -self.mult_x end
            if type == "1" then
                --self.mult_y = 2
                self.mult_y = (round(tileHeight*2/8))
            elseif type == "2" then
                --self.mult_y = -2
                self.mult_y = -(round(tileHeight*2/8))
            end
            if round(self.y_coord) <= -tileHeight then
                if self:get_facing() == Direction.Right and round(self.x_coord) >= tileWidth then
                    if self:get_tile(Direction.UpRight, 1):is_hole() then
                        self:get_animation():set_state("1")
                        self:get_animation():refresh(self:sprite())
                        self.can_move = 3
                    else
                        self:teleport(self:get_tile(Direction.UpRight, 1), ActionOrder.Immediate)
                        self.x_coord = -tileWidth
                        self.y_coord = -self.y_coord
                    end
                elseif self:get_facing() == Direction.Left and round(self.x_coord) <= -tileWidth then
                    if self:get_tile(Direction.UpLeft, 1):is_hole() then
                        self:get_animation():set_state("1")
                        self:get_animation():refresh(self:sprite())
                        self.can_move = 3
                    else
                        self:teleport(self:get_tile(Direction.UpLeft, 1), ActionOrder.Immediate)
                        self.x_coord = tileWidth
                        self.y_coord = -self.y_coord
                    end
                end
                --self.y_coord = tileHeight
            elseif round(self.y_coord) >= tileHeight then
                if self:get_facing() == Direction.Right and round(self.x_coord) >= tileWidth then
                    if self:get_tile(Direction.DownRight, 1):is_hole() then
                        self:get_animation():set_state("1")
                        self:get_animation():refresh(self:sprite())
                        self.can_move = 3
                    else
                        self:teleport(self:get_tile(Direction.DownRight, 1), ActionOrder.Immediate)
                        self.x_coord = -tileWidth
                        self.y_coord = -self.y_coord
                    end
                elseif self:get_facing() == Direction.Left and round(self.x_coord) <= -tileWidth then
                    if self:get_tile(Direction.DownLeft, 1):is_hole() then
                        self:get_animation():set_state("1")
                        self:get_animation():refresh(self:sprite())
                        self.can_move = 3
                    else
                        self:teleport(self:get_tile(Direction.DownLeft, 1), ActionOrder.Immediate)
                        self.x_coord = tileWidth
                        self.y_coord = -self.y_coord
                    end
                end
                --self.y_coord = -tileHeight
            end
            self:set_offset(self.x_coord*2, self.y_coord*2)
        elseif self.can_move == 3 then
            if self:get_animation():get_state() == "1" then
                self:get_animation():on_complete(function()
                    self:erase()
                end)
            end
        end
    end
    hellsrolling.attack_func = function(self, other)
        if Battle.Obstacle.from(other) == nil then
            Engine.play_audio(AudioType.Hurt, AudioPriority.Low)
		else
			Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
		end
    end
    hellsrolling.can_move_to_func = function(tile)
        return true
    end
    user:get_field():spawn(hellsrolling, tile)
    return hellsrolling
end

local function create_darknessoverload(user, tile)
    local darknessoverload = graphic_init("artifact", 0, 0, DARKNESSOVERLOAD_TEXTURE, DARKNESSOVERLOAD_ANIMPATH, "0", Playback.Once, -3, user, user:get_facing())
    darknessoverload:get_animation():on_complete(function()
        darknessoverload:erase()
    end)
    darknessoverload.on_spawn_func = function()
        Engine.play_audio(DARKNESSOVERLOAD_AUDIO, AudioPriority.Low)
    end
    user:get_field():spawn(darknessoverload, tile)
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 1), "DARKNESSOVERLOAD")
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 2), "DARKNESSOVERLOAD")
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 1):get_tile(Direction.Up, 1), "DARKNESSOVERLOAD")
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 2):get_tile(Direction.Up, 1), "DARKNESSOVERLOAD")
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 1):get_tile(Direction.Down, 1), "DARKNESSOVERLOAD")
    create_hitbox(user, tile:get_tile(darknessoverload:get_facing(), 2):get_tile(Direction.Down, 1), "DARKNESSOVERLOAD")
    return darknessoverload
end

local function create_afterimage(user, alpha, tile1, tile2)
    local image = graphic_init("spell", 0, 0, FORTE_MOVE2_TEXTURE, FORTE_MOVE2_ANIMPATH, "IDLE_1", Playback.Once, -1, user, user:get_facing())
    local anim = user:get_animation()
    anim:load(FORTE_ANIMPATH)
    anim = user.anim
    anim:set_playback(Playback.Loop)
    image:set_palette(FORTE_MOVE_PALETTE)
    image:set_color(Color.new(66, 99, 255, alpha))
    image:sprite():set_color_mode(ColorMode.Additive)
	image.slide_started = false
    image.flickering = 0
	image.update_func = function(self)
        self.flickering = self.flickering + 1
        if self.flickering == 1 or self.flickering == 2 then
            self:reveal()
        elseif self.flickering == 3 then
            self:hide()
        elseif self.flickering > 3 then
            self.flickering = 0
        end
		if not self:is_sliding() then
			if self:get_tile() == tile2 and self.slide_started then 
				self:erase()
			end
			local ref = self
			self:slide(tile2, frames(user.move_frames), frames(0), ActionOrder.Voluntary, function()
				ref.slide_started = true 
			end)
		end
	end
	image.can_move_to_func = function(tile)
		return true
	end
	user:get_field():spawn(image, tile1)
	return image
end

-- The "Afterimage Spawner" function.
-- Creates afterimages for Forte.
-- Function by Alrysc, edited by K1rbYat1Na.
local function afterimage_spawner(user, tile1, tile2)
    local spawner = graphic_init("spell", 0, 0, false, false, false, false, false, user, user:get_facing())
    spawner.frames = 0
	spawner.update_func = function(self)
        self.frames = self.frames + 1
        if self.frames == 4 then
            create_afterimage(user, 100, tile1, tile2) -- Creates first afterimage.
        elseif self.frames == 7 then
            create_afterimage(user, 150, tile1, tile2) -- Creates second afterimage.
        elseif self.frames >= 8 then
            self:erase()
        end
	end
	spawner.can_move_to_func = function(tile)
		return true
	end
	user:get_field():spawn(spawner, tile1)
	return spawner
end

-- The "Create BlackBarrier" function.
-- Creates a Black Barrier for Forte. The Barrier can't be damage when Forte is moving. Every time Forte uses Darkness Overload, he removes the barrier. After the attack, creates a new one.
-- Function by Alrysc, edited by K1rbYat1Na.
local function create_blackbarrier(user)
    local fading = false
    local isWind = false
    local barrier = Battle.Spell.new(user:get_team()) -- BlackBarrier is a Spell, so it doesn't animate during TFC.
    barrier.HP = 150
    barrier:sprite():set_layer(-3)
    barrier:set_texture(BLACKBARRIER_TEXTURE, true)
    barrier:set_offset(0,0)
    barrier:get_animation():load(BLACKBARRIER_ANIMPATH)
    barrier:get_animation():set_state("0")
    barrier:get_animation():refresh(barrier:sprite())
    barrier:get_animation():set_playback(Playback.Loop)
    barrier:set_float_shoe(true)
    user:get_field():spawn(barrier, user:get_tile())
    local barrier_defense_rule = Battle.DefenseRule.new(30000, DefenseOrder.Always) -- Keristero's MetGuard is 0
    barrier_defense_rule.can_block_func = function(judge, attacker, defender)
        local attacker_hit_props = attacker:copy_hit_props()
        if (attacker_hit_props.flags & Hit.Impact == Hit.Impact) and attacker_hit_props.damage > 0 then 
            barrier.HP = barrier.HP - attacker_hit_props.damage
            judge:block_damage()
        end
        if attacker_hit_props.element == Element.Wind then
            isWind = true
        end
    end
    user:add_defense_rule(barrier_defense_rule)
    barrier.can_move_to_func = function(tile) 
        return true
    end
    local function remove_barrier()
        user:remove_defense_rule(barrier_defense_rule)
        barrier:delete()
    end
    barrier.update_func = function(self)
        self:set_facing(user:get_facing())
        if user:is_deleted() then 
            remove_barrier()
        end
        if self:get_tile() ~= user:get_tile() then
            self:teleport(user:get_tile(), ActionOrder.Immediate)
        end
        if isWind and not fading then 
            remove_barrier()
        end
        if self.HP <= 0 and not fading then
            remove_barrier()
        end
        if barrier_defense_rule:is_replaced() then
            self:delete()
        end
    end
    barrier.delete_func = function(self)
        user:remove_defense_rule(barrier_defense_rule)
    end
    return barrier
end

function package_init(self)
    FORTE_TEXTURE = Engine.load_texture(_folderpath.."gfx/forte.grayscaled.png")
    FORTE_PALETTE = Engine.load_texture(_folderpath.."gfx/battle_v1.palette.png")
    FORTE_MOVE_TEXTURE = Engine.load_texture(_folderpath.."gfx/move.grayscaled.png")
    FORTE_MOVE_PALETTE = Engine.load_texture(_folderpath.."gfx/move_v1.palette.png")
    self:set_name("Forte") -- Sets Forte's name.
	local rank = self:get_rank() -- Gets Forte's rank.
    self.damage = 100 -- Damage for Forte's collision hitbox.
    self.damage_shootingbuster = 100 -- Damage for Shooting Buster.
    self.damage_darkarmblade = 100 -- Damage for Dark Arm Blade.
    self.damage_hellsrolling = 200 -- Damage for Hell's Rolling.
    self.damage_darknessoverload = 300 -- Damage for Darkness Overload.
    self.can_use_blackbarrier = false -- Determines whether Forte can use Black Barrier.
    self.blackbarrier = nil -- Forte's internal variable for a Black Barrier.
    self.shootingbuster_delay = 10
    self.shootingbuster_end = 172
    self.attacked_once = false -- Determines whether Forte attacked once.
    self.slide_started = false -- Determines whether Forte started sliding.
    self.change_facing = 0 -- The "Change Facing" variable. If 0 - doesn't change Forte's facing. If 1 - reverses Forte's facing. If 2 - restores Forte's facing.
    self.darkarmblade_behind = false
    --self.skip_darkarmblade1 = false
    --self.skip_darkarmblade2 = false
    --self.skip_darkarmblade3 = false
    self.skip_shootingbuster = false -- Determines whether Shooting Buster should be skipped.
    self.skip_hellsrolling = false -- Determines whether Hell's Rolling should be skipped.
    self.skip_darknessoverload = false -- Determines whether Darkness Overload should be skipped.

    self.next_tile = nil -- Forte's internal variable for Next tile.
    self.prev_tile = nil -- Forte's internal variable for Previous tile.
    self.original_tile = nil -- Forte's internal variable for Original tile.
    self.darkarmblade_tile1 = nil -- Forte's internal variable for a tile for Dark Arm Blade #1.
    self.darkarmblade_tile2 = nil -- Forte's internal variable for a tile for Dark Arm Blade #2.
    self.darkarmblade_tile3 = nil -- Forte's internal variable for a tile for Dark Arm Blade #3.
    self.rnd_moveset_number = nil
    self.base_idle_speed = 22
    --self.idle_speed_before_shootingbuster = 23
    self.move_frames = 12

    -- Chance /16. I'm going to run these when the pattern is complete and when the flinch finishes, respectively
        -- These skips will be very implementation-specific, so don't use them as future references
    self.chance_to_skip_idle_after_flinch = 2
    self.chance_to_halve_idle_after_flinch = 3

    if rank == Rank.SP then -- If Forte's rank is SP.
        FORTE_PALETTE = Engine.load_texture(_folderpath.."gfx/battle_sp.palette.png")
        FORTE_MOVE_PALETTE = Engine.load_texture(_folderpath.."gfx/move_sp.palette.png")
        self:set_health(3000)
        self.damage = 200
        self.damage_shootingbuster = 200
        self.damage_darkarmblade = 200
        self.damage_hellsrolling = 400
        self.damage_darknessoverload = 600
        self.shootingbuster_delay = 8
        self.shootingbuster_end = 168
        self.base_idle_speed = 17
        self.move_frames = 8
        --self.idle_speed_before_shootingbuster = 25
    elseif rank == Rank.NM then -- If Forte's rank is NM (XX).
        FORTE_PALETTE = Engine.load_texture(_folderpath.."gfx/battle_nm.palette.png")
        FORTE_MOVE_PALETTE = Engine.load_texture(_folderpath.."gfx/move_nm.palette.png")
        self:set_health(4000)
        self.damage = 300
        self.damage_shootingbuster = 300
        self.damage_darkarmblade = 300
        self.damage_hellsrolling = 600
        self.damage_darknessoverload = 900
        self.can_use_blackbarrier = true
        self.shootingbuster_delay = 6
        self.shootingbuster_end = 176
        self.base_idle_speed = 12
        self.move_frames = 6
        --self.idle_speed_before_shootingbuster = 20
    else
        self:set_health(2000)
    end

    self.idle_speed = self.base_idle_speed 

    self:set_texture(FORTE_TEXTURE, true)
    self:store_base_palette(FORTE_PALETTE)
    self:set_palette(self:get_base_palette())

    self:set_height(70)
    self:set_explosion_behavior(5, 1, true)
    self:set_offset(0,0)
	self:set_facing(Direction.Left)
    self.orig_facing = self:get_facing()
	self:set_element(Element.None)
	self:set_float_shoe(true)
	self:set_air_shoe(false)
    self:share_tile(false)

    self.orbs = self:create_node() --Nodes automatically attach to what you create them off of. No need to spawn!
    self.orbs:set_texture(ORBS_TEXTURE) --Just set their texture...
    self.orbs:set_layer(-1) --Set their layer, they're already a sprite...
    self.orbs_anim = Engine.Animation.new(ORBS_ANIMPATH) --And they have no get_animation, so we create one...
    --self.orbs_anim:copy_from(self:get_animation()) --Load or copy the animation and do the normal stuff...
    self.orbs_anim:set_state("0")
    self.orbs_anim:set_playback(Playback.Loop)
    self.orbs_anim:refresh(self.orbs)
    local ref = self
    --This is for animating the node.
    self.animate_component = Battle.Component.new(self, Lifetimes.Battlestep)
    self.animate_component.update_func = function(self, dt)
        ref.orbs_anim:update(dt, ref.orbs)
    end
    self:register_component(self.animate_component)

    local anim = self:get_animation()
    anim:load(FORTE_ANIMPATH)
    self.anim = include("enemy_base_v1/entry.lua")
    anim = self.anim
    anim:set_owner(self)
    anim:set_state("IDLE", {
        {duration=7, state="IDLE_1"},
        {duration=6, state="IDLE_2"},
        {duration=6, state="IDLE_3"},
        {duration=7, state="IDLE_4"},
        {duration=6, state="IDLE_5"},
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
    self.reserving_obstacle = Battle.Obstacle.new(self:get_team())

    self.on_spawn_func = function(self)
        self:get_field():spawn(self.reserving_obstacle,0,0)
        fix_context(self)
        if self:get_rank() == Rank.NM then
            self:set_name("ForteXX")
        end
        --[[
        self.before_battle_start_animater = Battle.Artifact.new()
        self:get_field():spawn(self.before_battle_start_animater, 7, 4)
        self.before_battle_start_animater.update_func = function()
            self.anim:tick_animation()
        end]]
    end

    self.battle_start_func = function(self)
        if self.can_use_blackbarrier then
            Engine.play_audio(BLACKBARRIER_AUDIO, AudioPriority.Low)
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
                self.blackbarrier = create_blackbarrier(self)
            end
        end
        --self.before_battle_start_animater:delete()
    end

    -- Setting names here is just convenience if I want to print the state I'm in later
    self.states = {
        idle = {name = "idle", func = idle},
        move = {name = "move", func = move},
        move_for_shootingbuster = {name = "move_for_shootingbuster", func = move_for_shootingbuster},
        move_for_hellsrolling = {name = "move_for_hellsrolling", func = move_for_hellsrolling},
        flinch = {name = "flinch", func = flinch},
        
        start_sub_pattern = {name = "start_sub_pattern"},
        finish_sub_pattern = {name = "finish_sub_pattern"},

        shootingbuster = {name = "shootingbuster", func = shootingbuster},
        darkarmblade1 = {name = "darkarmblade1", func = darkarmblade1},
        darkarmblade3 = {name = "darkarmblade3", func = darkarmblade3},
        hellsrolling = {name = "hellsrolling", func = hellsrolling},
        darknessoverload = {name = "darknessoverload", func = darknessoverload},

        choose_attack = {name = "choose_attack", func = choose_attack}
    }
    
    local s = self.states

    reconstruct_pattern(self)
 
    self.pattern_index = 1
    self.in_sub_pattern = false

    self.first_act = true
    self.second_act = false
    self.third_act = false
    self.fourth_act = false
    self.fifth_act = false
    self.sixth_act = false
    self.seventh_act = false
    self.eighth_act = false
    self.ninth_act = false
    self.tenth_act = false
    self.eleventh_act = false
    self.twelfth_act = false
    self.thirteenth_act = false
    self.fourteenth_act = false
    self.fifteenth_act = false
    self.sixteenth_act = false
    self.seventeenth_act = false

    self.state_done = false

    self.state = self.pattern[1]

    self.first_flinch = true

    self.hit_func = function(from_stun)
        debug_print("Hit func runs")
        self.counterable_component.timer = 0
        self:toggle_counter(false)
        self.flinching = false
        self.first_act = false
        self.state_done = false
        --self.moving_to_enemy_tile = false
        if self.first_flinch then 
            --self.state.cleanup
            self.last_state = self.state
            debug_print("Hit! Set last state to ", self.state.name)
            if self.state ~= self.states.idle and self.state ~= self.states.move then 
               --increment_pattern(self)
            end
            self.first_flinch = false
        end
        self.state = self.states.flinch
        -- This is unused for this boss
        if self.slide_component ~= nil then 
            debug_print("Hit while moving.")
            self.slide_component:eject()
            self.slide_component = nil
            self:set_offset(0,0)
            if self.slide_dest and self:get_tile() ~= self.slide_dest then 
                debug_print("Hit before reaching destination.")
                self:get_tile():remove_entity_by_id(self.reserving_obstacle:get_id())
                self:get_tile():remove_entity_by_id(self:get_id())
                self.slide_dest:add_entity(self)
                self.slide_dest = nil
            end
        end
        flinch(self, from_stun)
    end

    self.delete_func = function(self)
        self.reserving_obstacle:erase()
        self.update_func = function(self)
            self:get_animation():set_state("STUN_1")
            self.state = self.states.flinch
        end
    end

    -- Unused for this boss
    --self.moving_to_enemy_tile = false
    self.counter = 0
    self.collision_available = true
    self.counterable = 0

    local ref = self
    self.counterable_component = Battle.Component.new(self, Lifetimes.Battlestep)
    self.counterable_component.timer = 0
    self.counterable_component.update_func = function(self)
        if self.timer > 0 then
            debug_print("COUNTERABLE")
            self.timer = self.timer - 1
            ref:toggle_counter(true)
        else
            ref:toggle_counter(false)
        end
    end
    self:register_component(self.counterable_component)

    self:register_status_callback(Hit.Stun, function() self.hit_func(true) end)
    self:register_status_callback(Hit.Freeze, function() self.hit_func(true) end)
    self:register_status_callback(Hit.Flinch, self.hit_func)
    self:register_status_callback(Hit.Root, function() self.rooted = 120 end)
    --self:register_status_callback(Hit.Drag, self.hit_func)

    -- Bring it back next build. For now, relying on the stun callback
    self.on_countered = function(self)
        debug_print("Countered")
        --self.counterable_component.timer = 0
        --self:toggle_counter(false)
        self.hit_func(true)
    end

    self.can_move_to_func = function(tile)
        if self.rooted > 0 then return false end
        if tile:is_edge() or not tile:is_walkable() then
            return false
        end
        if(tile:is_reserved({self:get_id(),self.reserving_obstacle:get_id()})) then
            return false
        end
        if tile == self:get_tile() then
            return true
        end
        --[[
        if not self.moving_to_enemy_tile and (tile:get_team() ~= self:get_team()) then
            return false
        end
        ]]

        --return not check_obstacles(tile, self) and not check_characters_true(tile, self)
        return true
    end

    self.use_flickering = false
    self.flickering = 0
    
    self.flash_defense = Battle.DefenseRule.new(10000, DefenseOrder.CollisionOnly)
    self.flash_defense.can_block_func = function(judge, attacker, defender)
        local attacker_hit_props = attacker:copy_hit_props()
        if attacker_hit_props.flags & Hit.Flash == Hit.Flash then
            self.use_flickering = false
            self.flickering = 0
            self:reveal()
        end
    end
    --self:add_defense_rule(self.flash_defense)

    self.rooted = 0
    self.update_func = function(self)
        debug_print("     ", self.state.name, self:get_animation():get_state())
        if self.rooted > 0  then self.rooted = self.rooted - 1 end
        self.state.func(self)
        self.anim:tick_animation()

        -- When we tick animation, we may run increment_pattern. 
        -- The new state isn't run until next frame, so our anim state lasts one more frame when it finishes
        -- Calling our state one time to set things up will avoid this. Mostly sure this doesn't have major unintended consequences,
        -- especially as most state.func only set state and callbacks for frame 1
        -- Problem is, now I may have a frame 1 callback but I don't run it until next frame
        while self.first_act
        do
            self.state.func(self)
            self.anim:tick_animation()
        end
        check_collision(self)

        if self.use_flickering then
            self.flickering = self.flickering + 1
            if self.flickering == 1 or self.flickering == 2 then
                self:reveal()
            elseif self.flickering == 3 then
                self:hide()
            elseif self.flickering > 3 then
                self.flickering = 0
            end
        else
            self.flickering = 0
            self:reveal()
        end
    end
end

-- The "Create Collision Attack" function.
-- Creates an attacking spell on Forte's current tile.
-- Function by Alrysc.
function create_collision_attack(self, tile)
    local spell = Battle.Spell.new(self:get_team())
    local hit_props = HitProps.new(
        self.damage,
        Hit.Impact | Hit.Flinch | Hit.Flash,
        self:get_element(), 
        self:get_context(), 
        Drag.None
    )
    spell:set_hit_props(hit_props)
    spell.update_func = function(self)
        tile:attack_entities(self)
        self:delete()
    end
    spell.attack_func = function(self, other)
        if Battle.Obstacle.from(other) == nil then
            Engine.play_audio(AudioType.Hurt, AudioPriority.Low)
		else
			Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
		end
    end
    self:get_field():spawn(spell, tile)
end

-- The "Check Collision" function.
-- Function by Alrysc.
-- TODO: When we get is_passthrough or something, check to see if target became flashing before 
    -- we are allowed to spawn another one. Don't want to instakill viruses
-- self.collision_available can do something related to that. Does nothing now
function check_collision(self)
    local t = self:get_tile()
    if self.collision_available and check_characters(t, self) then 
        create_collision_attack(self, t)
    end
end

-- The "Idle" move function.
-- Function by Alrysc, edited by K1rbYat1Na.
function idle(self)
    if self.first_act then
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_offset(self:get_offset().x, 0)
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        -- This is an old check for when I extended idle time by doing two idle states in a row, when characters have an animated idle.
            -- Not needed if I instead use a timer.
        if self.anim:get_state() ~= "IDLE" then 
            debug_print("Idle with ", self.idle_speed)
            self.anim:set_state("IDLE", {
                {duration=7, state="IDLE_1"},
                {duration=6, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=7, state="IDLE_4"},
                {duration=6, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })
        end
        self.anim:set_playback(Playback.Loop) -- Loops the animation.
        self.counter = 0
        self.first_act = false
    end
    self.counter = self.counter + 1
    if self.counter == 1 then
        if self.rooted > 0 then
            self.idle_speed = self.base_idle_speed
            increment_pattern(self)
        end
    elseif self.counter > self.idle_speed then
        -- Extra catch for after leaving attack. Attack will double idle speed once, so making sure to reset it after
        if self.idle_speed > self.base_idle_speed then 
            self.idle_speed = self.base_idle_speed
        end
        increment_pattern(self)
    end
    --[[
    self.looped = false
    if self.state_done then 
        debug_print("State done")
    end
    ]]--
end

-- Function by Alrysc.
function end_sub_pattern(self)
    while(self.in_sub_pattern)
    do
        increment_pattern(self)
    end
end

-- Function by Alrysc, edited by K1rbYat1Na.
function flinch(self, from_stun)
    debug_print("Flinch played")
    --[[
    if self.prev_tile ~= nil and self:get_tile():get_team() ~= self:get_team() then
        self:teleport(self.prev_tile, ActionOrder.Voluntary, nil)
        self:get_tile():remove_entity_by_id(self:get_id())
        self.prev_tile:add_entity(self)
        self.prev_tile = nil
    end
    ]]
    if self:get_tile() == self.next_tile then
        local orig_tile = self.next_tile
        self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:remove_entity_by_id(self:get_id())
        self.next_tile = orig_tile
        self.next_tile:add_entity(self)
        self.next_tile = nil
    elseif self:get_tile() == self.prev_tile then
        local orig_tile = self.prev_tile
        self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
        self.prev_tile:remove_entity_by_id(self:get_id())
        self.prev_tile = orig_tile
        self.prev_tile:add_entity(self)
        self.prev_tile = nil
    end
    if self.original_tile then
        self:teleport(self.original_tile, ActionOrder.Immediate, nil)
        self.get_tile():remove_entity_by_id(self.reserving_obstacle:get_id())
        self:get_tile():remove_entity_by_id(self:get_id())
        self.original_tile:add_entity(self)
        self.original_tile = nil
    end
    if self.orbs_anim:get_state() == "1" then
        self.orbs_anim:set_state("0")
        self.orbs_anim:set_playback(Playback.Loop)
        self.orbs_anim:refresh(self.orbs)
    end
    self:set_facing(self.orig_facing)
    self.change_facing = 0
    if self.rooted > 0 then self.rooted = 0 end
    debug_print("I am flinching")
    if not self.flinching then
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_offset(self:get_offset().x, 0)
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        local frames = {}
        if from_stun then
            frames[1] = {duration=1, state="STUN_1"}
        else
            frames[1] = {duration=2, state="FLINCH_1"}
            frames[2] = {duration=1, state="FLINCH_2"}
            frames[3] = {duration=2, state="FLINCH_3"}
            frames[4] = {duration=18, state="FLINCH_4"}
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
                debug_print("Attempt skip, because last state was idle")
                has_skipped = maybe_skip_after_flinch(self)
            end
            
            debug_print("I am done flinching")
            debug_print("Anim done")
            self.flinching = false
            self.state_done = true
            self.first_flinch = true

            debug_print("Done")
            self.state_done = false
            if self.last_state ~= self.states.idle and self.last_state ~= self.states.move then 
                debug_print("Last state was not idle or move", self.last_state.name)
                increment_pattern(self)
            else--if not has_skipped then 
                -- If we were in idle or move, go back to it and try again
                -- Unless we were in a sub pattern. Still end that.
                debug_print("Last state was idle or move")
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

-- Function by Alrysc.
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
        debug_print("We halved")
    elseif r <= (chance_skip + chance_halve) then 
        debug_print("We skipped")
        self.idle_speed = 0
        return true
    end

    return false
end

-- The "Highlight Tiles" function.
-- Function by Alrysc.
function highlight_tiles(self, list, time)
    local spell = Battle.Spell.new(self:get_team())
    local ref = self
    spell.update_func = function(self)
        for i=1, #list do 
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
    self:get_field():spawn(spell, self:get_tile())
    return spell
end

-- The "Move" move function.
-- Function by Alrysc, edited by K1rbYat1Na.
function move(self)
    if self.first_act then
        self.first_act = false
        if self.rooted > 0 then
            self.idle_speed = self.base_idle_speed
            increment_pattern(self)
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            self.prev_tile = self:get_tile()
            local tile = choose_move(self, self:get_field())
            if not tile then
                tile = self:get_tile()
            end
            if self.can_move_to_func(tile) then
                self.next_tile = tile
                self:slide(self.next_tile, frames(self.move_frames), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self.prev_tile, self.next_tile)
                    self.slide_started = true
                end)
            else
                self.idle_speed = self.base_idle_speed
                increment_pattern(self)
            end
        end
    end
    if self.next_tile then
        self.next_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:reserve_entity_by_id(self:get_id())
    end
    if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
        local orig_tile = self.next_tile
        self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:remove_entity_by_id(self:get_id())
        self.next_tile = orig_tile
        self.next_tile:add_entity(self)
        --self.next_tile = nil
        if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
        else
            self.blackbarrier:reveal()
        end
        if self:get_tile():get_team() == self:get_team() then
            self:share_tile(false)
        end
        self.slide_started = false
        self:set_offset(self:get_offset().x, self:get_offset().y+400)
        self.idle_speed = self.base_idle_speed
        increment_pattern(self)
    end
end

-- The "Move for Shooting Buster" move function.
-- Function by K1rbYat1Na.
function move_for_shootingbuster(self)
    if self.first_act then
        self.first_act = false
        if self.rooted > 0 then
            self.idle_speed = self.base_idle_speed
            increment_pattern(self)
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            self.prev_tile = self:get_tile()
            local tile = choose_move_for_shootingbuster(self, self:get_field())
            if not tile or not self.can_move_to_func(tile) then
                self.skip_shootingbuster = true
                self.idle_speed = self.base_idle_speed --???
                increment_pattern(self)
            else
                self.next_tile = tile
                self:slide(self.next_tile, frames(self.move_frames), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self.prev_tile, self.next_tile)
                    self.slide_started = true
                end)
            end
        end
    end
    if self.next_tile then
        self.next_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:reserve_entity_by_id(self:get_id())
    end
    if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
        local orig_tile = self.next_tile
        self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:remove_entity_by_id(self:get_id())
        self.next_tile = orig_tile
        self.next_tile:add_entity(self)
        --self.next_tile = nil
        if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
        else
            self.blackbarrier:reveal()
        end
        if self:get_tile():get_team() == self:get_team() then
            self:share_tile(false)
        end
        self.slide_started = false
        self:set_offset(self:get_offset().x, self:get_offset().y+400)
        self.idle_speed = self.base_idle_speed
        increment_pattern(self)
    end
end

-- The "Move for Hell's Rolling" move function.
-- Function by K1rbYat1Na.
function move_for_hellsrolling(self)
    if self.first_act then
        self.first_act = false
        if self.rooted > 0 or choose_move_to_center_back(self, self:get_field()) == self:get_tile() then
            self.idle_speed = self.base_idle_speed --???
            increment_pattern(self)
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            self.prev_tile = self:get_tile()
            local tile = choose_move_to_center_back(self, self:get_field())
            if not tile or not self.can_move_to_func(tile) then
                self.skip_hellsrolling = true
                self.idle_speed = self.base_idle_speed --???
                increment_pattern(self)
            else
                self.next_tile = tile
                self:slide(self.next_tile, frames(self.move_frames), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self.prev_tile, self.next_tile)
                    self.slide_started = true
                end)
            end
        end
    end
    if self.next_tile then
        self.next_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:reserve_entity_by_id(self:get_id())
    end
    if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
        local orig_tile = self.next_tile
        self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
        self.next_tile:remove_entity_by_id(self:get_id())
        self.next_tile = orig_tile
        self.next_tile:add_entity(self)
        --self.next_tile = nil
        if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
        else
            self.blackbarrier:reveal()
        end
        if self:get_facing() ~= self.orig_facing then
            self:set_facing(self.orig_facing)
        end
        if self:get_tile():get_team() == self:get_team() then
            self:share_tile(false)
        end
        if self.can_move_to_func(self.next_tile) then
        else
            self.skip_hellsrolling = true
        end
        self.slide_started = false
        self:set_offset(self:get_offset().x, self:get_offset().y+400)
        self.idle_speed = self.base_idle_speed --???
        increment_pattern(self)
    end
end

function choose_attack(self)
    local atk_tbl = {}
    self.state = atk_tbl[self.r_atk]

    self.state.func(self)
    self.idle_speed = self.base_idle_speed * 2
end


-- The "Shooting Buster" move function.
-- Function by K1rbYat1Na.
function shootingbuster(self)
    if self.first_act then
        self.first_act = false
        if self.skip_shootingbuster then
            self.skip_shootingbuster = false
            self.idle_speed = self.base_idle_speed*2
            increment_pattern(self)
        else
            local frames = {}
            frames[1] = {duration=4, state="SHOOTINGBUSTER_1"}
            frames[2] = {duration=4, state="SHOOTINGBUSTER_2"}
            frames[3] = {duration=4, state="SHOOTINGBUSTER_3"}
            frames[4] = {duration=4, state="SHOOTINGBUSTER_2"}
            frames[5] = {duration=3, state="SHOOTINGBUSTER_3"}
            frames[6] = {duration=1, state="SHOOTINGBUSTER_3"}
            for i=6+1, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_4"}
            end
            for i=6+2, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_4"}
            end
            for i=6+3, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_4"}
            end
            for i=6+4, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_4"}
            end
            for i=6+5, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_5"}
            end
            for i=6+6, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_5"}
            end
            for i=6+7, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_5"}
            end
            for i=6+8, 6+170, 8 do
                frames[i] = {duration=1, state="SHOOTINGBUSTER_5"}
            end
            frames[177] = {duration=1, state="SHOOTINGBUSTER_2"}
            frames[178] = {duration=1, state="SHOOTINGBUSTER_2"}
            frames[179] = {duration=1, state="SHOOTINGBUSTER_2"}
            frames[180] = {duration=1, state="SHOOTINGBUSTER_2"}
            frames[181] = {duration=1, state="SHOOTINGBUSTER_2"}
            frames[182] = {duration=5, state="SHOOTINGBUSTER_1"}
            self.anim:set_state("SHOOTINGBUSTER", frames)
            self.anim:on_frame(6, function()
                self.counterable_component.timer = 10+2 -- Makes Forte counterable for 10+2 frames.
            end)
            for i=6+2, 6+self.shootingbuster_end, self.shootingbuster_delay do
                self.anim:on_frame(i, function()
                    local rnd_tile = math.random(0,2) -- If 0 - Shooting Buster targets the nearest enemy, If 1 or 2 - targers a random tile.
                    local clst_enmy = self:get_field():find_nearest_characters(self, function(other)
                        return other and not other:is_team(self:get_team())
                    end)
                    if rnd_tile == 0 and clst_enmy[1] ~= nil then
                        create_shootingbuster(self, clst_enmy[1]:get_tile())
                    else
                        local tiles = self:get_field():find_tiles(function(tile)
                            return tile and not tile:is_edge() and tile:get_team() ~= self:get_team()
                        end)
                        create_shootingbuster(self, tiles[math.random(1, #tiles)])
                    end
                    local rnd_x = math.random(4,35)*2
                    if self:get_facing() == Direction.Left then
                        rnd_x = -rnd_x
                    end
                    local shoot_fx = graphic_init("artifact", rnd_x, (math.random(-47,-18)*2), EFFECT_TEXTURE, EFFECT_ANIMPATH, "8", Playback.Once, -9, self, self:get_facing())
                    shoot_fx:get_animation():on_complete(function() shoot_fx:erase() end)
                    self:get_field():spawn(shoot_fx, self:get_tile())
                end)
            end
            self.anim:on_complete(function()
                self.idle_speed = self.idle_speed*2
                increment_pattern(self) -- Next move.
            end)
        end
    end
end

-- The "Dark Arm Blade (once)" move function.
-- A move: Forte moves to front of the nearest enemy and uses Dark Arm Blade #1 (Type 1); Then moves behind the enemy and uses Dark Arm Blade #2 (Type 2); Then moves to front of the enemy and uses Dark Arm Blade #3 (Type 1); Then moves to a random tile of his field.
-- Function by K1rbYat1Na.
function darkarmblade1(self)
    if self.first_act then -- Act #1: BEFORE moving in front of the nearest enemy.
        self.first_act = false
        if self.rooted > 0 then -- If Forte is rooted.
            self.idle_speed = 13
            increment_pattern(self) -- Skips to next move.
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:share_tile(true) -- Allows other entities to step on Forte's current tile.
            --self.moving_to_enemy_tile = true
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            self.prev_tile = self:get_tile() -- Sets Forte's current tile as Previous tile.
            self.original_tile = self.prev_tile
            local tile = choose_move_to_enemy_front(self, self:get_field()) -- Chooses the tile in front of the nearest enemy.
            if not tile or not self.can_move_to_func(tile) then
                self.idle_speed = 13
                increment_pattern(self) -- Skips to next move.
            else
                self.next_tile = tile
                self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self.prev_tile, self.next_tile)
                    self.slide_started = true
                    self.second_act = true
                end)
            end
        end
    end
    if self.second_act then -- Act #2: Moving in front of the nearest enemy.
        if self.original_tile then
            self.original_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
            self.original_tile:reserve_entity_by_id(self:get_id())
        end
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal() -- Reveals Forte's Black Barrier.
            end
            if self:get_tile():get_team() == self:get_team() then -- If Forte's current tile's team is Forte's team.
                self:share_tile(false)  -- Allows other entities to step on Forte's current tile.
            end
            if self.can_move_to_func(self.next_tile) then
                --print("can_move_to_func")
            else
                --print("not can_move_to_func")
                self.idle_speed = 13
                self:teleport(self.prev_tile, ActionOrder.Immediate)
                increment_pattern(self) -- Skips to next move.
            end
            self.slide_started = false
            self:set_facing(self.orig_facing)
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.second_act = false
            self.third_act = true
            self.fourth_act = true
            self.idle_speed = 10
        else
            --print("FAILED")
        end
    end
    if self.third_act then -- Act #3: Idle.
        self.third_act = false -- Act #3 executes once.
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        if self.anim:get_state() ~= "IDLE" then 
            self.anim:set_state("IDLE", {
                {duration=7, state="IDLE_1"},
                {duration=6, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=7, state="IDLE_4"},
                {duration=6, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })
        end
        self.anim:set_playback(Playback.Loop) -- Loops the animation.
        self.counter = 0
    end
    if self.fourth_act then -- Act #4: Idle-Wait.
        self.counter = self.counter + 1
        if self.counter == 1 then
            if self.rooted > 0 then
                self.idle_speed = self.base_idle_speed
                self.fourth_act = false -- Deactivates Act #4.
                self.fifth_act = true -- Activates Act #5.
                self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
            end
        elseif self.counter > self.idle_speed then
            if self.idle_speed > self.base_idle_speed then 
                self.idle_speed = self.base_idle_speed
            end
            self.fourth_act = false -- Deactivates Act #4.
            self.fifth_act = true -- Activates Act #5.
            self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
        end
    end
    if self.fifth_act then -- Act #5: Dark Arm Blade attack.
        self.fifth_act = false -- Act #5 executes once.
        self.anim:set_state("DARKARMBLADE", {
            {duration=3, state="DARKARMBLADE_1"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=4, state="DARKARMBLADE_3"},
        })
        self.anim:on_frame(3, function()
            create_darkarmblade1(self, self:get_tile(self:get_facing(), 1))
        end)
        self.anim:on_complete(function()
            self.original_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            if self:get_tile() ~= self.original_tile then
                self.original_tile:remove_entity_by_id(self:get_id())
                self.original_tile = nil
            end
            self.sixth_act = true
            self.seventh_act = true
        end)
    end
    if self.sixth_act then -- Act #6: BEFORE Moving back to own field.
        self.sixth_act = false -- Act #6 executes once.
        if self.rooted > 0 then
            self.idle_speed = self.base_idle_speed
            increment_pattern(self) -- Skips to next move.
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            --self.prev_tile = self:get_tile()
            --[[
            local orig_tile = self:get_tile()
            self.prev_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            self.prev_tile:remove_entity_by_id(self:get_id())
            self.prev_tile = orig_tile
            self.prev_tile:add_entity(self)
            self.prev_tile = nil
            ]]
            local tile = choose_move(self, self:get_field())
            if not tile or not self.can_move_to_func(tile) then
                tile = self:get_tile()
            end
            self.next_tile = tile
            self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                afterimage_spawner(self, self:get_tile(), self.next_tile)
                self.slide_started = true
            end)
        end
    end
    if self.seventh_act then -- Act #7: Moving back to own field.
        if self.next_tile then
            self.next_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
            self.next_tile:reserve_entity_by_id(self:get_id())
        end
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            local orig_tile = self.next_tile
            self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            self.next_tile:remove_entity_by_id(self:get_id())
            self.next_tile = orig_tile
            self.next_tile:add_entity(self)
            --self.next_tile = nil
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal()
            end
            if self:get_tile():get_team() == self:get_team() then
                self:share_tile(false)
            end
            self.slide_started = false
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.idle_speed = self.base_idle_speed
            increment_pattern(self)
        end
    end
end

-- The "Dark Arm Blade (thrice)" move function.
-- Function by K1rbYat1Na.
function darkarmblade3(self)
    -- DARK ARM BLADE 1
    if self.first_act then -- Act #1: BEFORE moving in front of the nearest enemy.
        self.first_act = false
        if self.rooted > 0 then
            self.idle_speed = 13
            increment_pattern(self) -- Skips to next move.
        else
            self.change_facing = 0
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:share_tile(true) -- Allows other entities to step on Forte's current tile.
            --self.moving_to_enemy_tile = true
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            self.prev_tile = self:get_tile() -- Sets Forte's current tile as Previous tile.
            self.original_tile = self.prev_tile
            local tile = choose_move_to_enemy_front(self, self:get_field()) -- Chooses the tile in front of the nearest enemy.
            if not tile then
                if not self.darkarmblade_behind then -- If can use Dark Arm Blade behind.
                    tile = choose_move_to_enemy_back(self, self:get_field()) -- Chooses the tile behind the nearest enemy.
                    if not tile then
                        self.idle_speed = 13
                        increment_pattern(self) -- Skips to next move.
                    else
                        self.change_facing = 1
                        self.darkarmblade_behind = true -- Cannot use Dark Arm Blade behind anymore.
                    end
                end
            end
            if tile and self.can_move_to_func(tile) then
                self.next_tile = tile
                self.darkarmblade_tile1 = tile
                self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self:get_tile(), self.next_tile)
                    self.slide_started = true
                    self.second_act = true
                end)
            else
                self.idle_speed = 13
                increment_pattern(self) -- Skips to next move.
            end
        end
    end
    if self.second_act then -- Act #2: Moving in front of the nearest enemy.
        if self.original_tile then
            self.original_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
            self.original_tile:reserve_entity_by_id(self:get_id())
        end
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal() -- Reveals Forte's Black Barrier.
            end
            if self:get_tile():get_team() == self:get_team() then -- If Forte's current tile's team is Forte's team.
                self:share_tile(false)  -- Allows other entities to step on Forte's current tile.
            end
            if self.can_move_to_func(self.next_tile) then
            else
                self.idle_speed = 10
                self:teleport(self.prev_tile, ActionOrder.Immediate)
                increment_pattern(self)
            end
            self.slide_started = false
            if self.change_facing == 1 then
                self:set_facing(Direction.reverse(self.orig_facing))
                self.change_facing = 2
            elseif self.change_facing == 2 then
                self:set_facing(self.orig_facing)
                self.change_facing = 0
            end
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.second_act = false
            self.third_act = true
            self.fourth_act = true
            self.idle_speed = 10
        end
    end
    if self.third_act then -- Act #3: Idle.
        self.third_act = false -- Act #3 executes once.
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        if self.anim:get_state() ~= "IDLE" then 
            self.anim:set_state("IDLE", {
                {duration=7, state="IDLE_1"},
                {duration=6, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=7, state="IDLE_4"},
                {duration=6, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })
        end
        self.anim:set_playback(Playback.Loop) -- Loops the animation.
        self.counter = 0
    end
    if self.fourth_act then -- Act #4: Idle-Wait.
        self.counter = self.counter + 1
        if self.counter == 1 then
            if self.rooted > 0 then
                self.idle_speed = self.base_idle_speed
                self.fourth_act = false -- Deactivates Act #4.
                self.fifth_act = true -- Activates Act #5.
                self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
            end
        elseif self.counter > self.idle_speed then
            if self.idle_speed > self.base_idle_speed then 
                self.idle_speed = self.base_idle_speed
            end
            self.fourth_act = false -- Deactivates Act #4.
            self.fifth_act = true -- Activates Act #5.
            self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
        end
    end
    if self.fifth_act then -- Act #5: Dark Arm Blade attack #1.
        self.fifth_act = false -- Act #5 executes once.
        self.anim:set_state("DARKARMBLADE", {
            {duration=3, state="DARKARMBLADE_1"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=4, state="DARKARMBLADE_3"},
        })
        self.anim:on_frame(3, function()
            create_darkarmblade1(self, self:get_tile(self:get_facing(), 1))
        end)
        self.anim:on_complete(function()
            self.sixth_act = true -- Activates Act #6.
        end)
    end
    -- DARK ARM BLADE 2
    if self.sixth_act then -- Act #6: Moving in front of the nearest enemy.
        self.sixth_act = false -- Act #6 executes once.
        if self.rooted > 0 then
            self.idle_speed = 13
            increment_pattern(self) -- Skips to next move.
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:share_tile(true) -- Allows other entities to step on Forte's current tile.
            --self.moving_to_enemy_tile = true
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            local tile = nil
            if not self.darkarmblade_behind then
                tile = choose_move_to_enemy_back(self, self:get_field()) -- Chooses the tile behind the nearest enemy.
            end
            if not tile or tile == self.darkarmblade_tile1 then
                tile = choose_move_to_enemy_front(self, self:get_field()) -- Chooses the tile in front of the nearest enemy.
                if not tile then
                    self.idle_speed = 13
                    self.seventh_act = false
                    self.sixteenth_act = true
                    self.seventeenth_act = true
                end
            else
            --end
            --if not self.darkarmblade_behind then
                self.change_facing = 1
                self.darkarmblade_behind = true -- Cannot use Dark Arm Blade behind anymore.
            end
            if tile and self.can_move_to_func(tile) then
                self.next_tile = tile
                self.darkarmblade_tile2 = tile
                self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self:get_tile(), self.next_tile)
                    self.slide_started = true
                    self.seventh_act = true -- Activates Act #7.
                end)
            else
                self.idle_speed = 13
                self.seventh_act = false
                self.sixteenth_act = true
                self.seventeenth_act = true
            end
        end
    end
    if self.seventh_act then -- Act #7: Moving in front of the nearest enemy.
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal() -- Reveals Forte's Black Barrier.
            end
            if self:get_tile():get_team() == self:get_team() then -- If Forte's current tile's team is Forte's team.
                self:share_tile(false)  -- Allows other entities to step on Forte's current tile.
            end
            if self.can_move_to_func(self.next_tile) then
            else
                self.idle_speed = 13
                self:teleport(self.prev_tile, ActionOrder.Immediate) -- Teleports Forte back to Previous tile.
                increment_pattern(self) -- Skips to next move.
            end
            self.slide_started = false
            if self.change_facing == 1 then
                self:set_facing(Direction.reverse(self.orig_facing))
                self.change_facing = 2
            elseif self.change_facing == 2 then
                self:set_facing(self.orig_facing)
                self.change_facing = 0
            end
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.seventh_act = false -- Deactivates Act #7.
            self.eighth_act = true -- Activates Act #8.
            self.ninth_act = true -- Activates Act #9.
            self.idle_speed = 10
        end
    end
    if self.eighth_act then -- Act #8: Idle.
        self.eighth_act = false -- Act #8 executes once.
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        if self.anim:get_state() ~= "IDLE" then 
            self.anim:set_state("IDLE", {
                {duration=7, state="IDLE_1"},
                {duration=6, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=7, state="IDLE_4"},
                {duration=6, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })
        end
        self.anim:set_playback(Playback.Loop) -- Loops the animation.
        self.counter = 0
    end
    if self.ninth_act then -- Act #9: Idle-Wait.
        self.counter = self.counter + 1
        if self.counter == 1 then
            if self.rooted > 0 then
                self.idle_speed = self.base_idle_speed
                self.ninth_act = false -- Deactivates Act #9.
                self.tenth_act = true -- Activates Act #10.
                self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
            end
        elseif self.counter > self.idle_speed then
            if self.idle_speed > self.base_idle_speed then 
                self.idle_speed = self.base_idle_speed
            end
            self.ninth_act = false -- Deactivates Act #9.
            self.tenth_act = true -- Activates Act #10.
            self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
        end
    end
    if self.tenth_act then -- Act #10: Dark Arm Blade attack #2.
        self.tenth_act = false -- Act #10 executes once.
        self.anim:set_state("DARKARMBLADE", {
            {duration=3, state="DARKARMBLADE_1"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=4, state="DARKARMBLADE_3"},
        })
        self.anim:on_frame(3, function()
            create_darkarmblade2(self, self:get_tile(self:get_facing(), 1))
        end)
        self.anim:on_complete(function()
            self.eleventh_act = true -- Activates Act #11.
        end)
    end
    -- DARK ARM BLADE 3
    if self.eleventh_act then -- Act #11: Moving in front of the nearest enemy.
        self.eleventh_act = false -- Act #11 executes once.
        if self.rooted > 0 then
            self.idle_speed = 13
            increment_pattern(self) -- Skips to next move.
        else
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:share_tile(true) -- Allows other entities to step on Forte's current tile.
            --self.moving_to_enemy_tile = true
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            local tile = choose_move_to_enemy_front(self, self:get_field()) -- Chooses the tile in front of the nearest enemy.
            if not tile or tile == self.darkarmblade_tile2 then
                if not self.darkarmblade_behind then -- If can use Dark Arm Blade behind.
                    tile = choose_move_to_enemy_back(self, self:get_field()) -- Chooses the tile behind the nearest enemy.
                end
                if not tile then
                    self.idle_speed = 13
                    self.twelfth_act = false
                    self.sixteenth_act = true
                    self.seventeenth_act = true
                else
                    self.change_facing = 1
                    self.darkarmblade_behind = true -- Cannot use Dark Arm Blade behind anymore.
                end
            end
            if tile and self.can_move_to_func(tile) then
                self.next_tile = tile
                self.darkarmblade_tile3 = tile
                self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                    afterimage_spawner(self, self:get_tile(), self.next_tile)
                    self.slide_started = true
                    self.twelfth_act = true -- Activates Act #12.
                end)
            else
                self.idle_speed = 13
                self.twelfth_act = false
                self.sixteenth_act = true
                self.seventeenth_act = true
            end
        end
    end
    if self.twelfth_act then -- Act #12: Moving in front of the nearest enemy.
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal() -- Reveals Forte's Black Barrier.
            end
            if self:get_tile():get_team() == self:get_team() then -- If Forte's current tile's team is Forte's team.
                self:share_tile(false)  -- Allows other entities to step on Forte's current tile.
            end
            if self.can_move_to_func(self.next_tile) then
            else
                self.idle_speed = 13
                self:teleport(self.prev_tile, ActionOrder.Immediate) -- Teleports Forte back to Previous tile.
                increment_pattern(self) -- Skips to next move.
            end
            self.slide_started = false
            if self.change_facing == 1 then
                self:set_facing(Direction.reverse(self.orig_facing))
                self.change_facing = 2
            elseif self.change_facing == 2 then
                self:set_facing(self.orig_facing)
                self.change_facing = 0
            end
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.twelfth_act = false -- Deactivates Act #12.
            self.thirteenth_act = true -- Activates Act #13.
            self.fourteenth_act = true -- Activates Act #14.
            self.idle_speed = 10
        end
    end
    if self.thirteenth_act then -- Act #13: Idle.
        self.thirteenth_act = false -- Act #13 executes once.
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        if self.anim:get_state() ~= "IDLE" then 
            self.anim:set_state("IDLE", {
                {duration=7, state="IDLE_1"},
                {duration=6, state="IDLE_2"},
                {duration=6, state="IDLE_3"},
                {duration=7, state="IDLE_4"},
                {duration=6, state="IDLE_5"},
                {duration=6, state="IDLE_6"},
            })
        end
        self.anim:set_playback(Playback.Loop) -- Loops the animation.
        self.counter = 0
    end
    if self.fourteenth_act then -- Act #14: Idle-Wait.
        self.counter = self.counter + 1
        if self.counter == 1 then
            if self.rooted > 0 then
                self.idle_speed = self.base_idle_speed
                self.fourteenth_act = false -- Deactivates Act #14.
                self.fifteenth_act = true -- Activates Act #15.
                self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
            end
        elseif self.counter > self.idle_speed then
            if self.idle_speed > self.base_idle_speed then 
                self.idle_speed = self.base_idle_speed
            end
            self.fourteenth_act = false -- Deactivates Act #14.
            self.fifteenth_act = true -- Activates Act #15.
            self.counterable_component.timer = 16+2 -- Makes Forte countarable for 16+2 frames.
        end
    end
    if self.fifteenth_act then -- Act #15: Dark Arm Blade attack #3.
        self.fifteenth_act = false -- Act #15 executes once.
        self.anim:set_state("DARKARMBLADE", {
            {duration=3, state="DARKARMBLADE_1"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=1, state="DARKARMBLADE_2"},
            {duration=4, state="DARKARMBLADE_3"},
        })
        self.anim:on_frame(3, function()
            create_darkarmblade1(self, self:get_tile(self:get_facing(), 1))
        end)
        self.anim:on_complete(function()
            self.sixteenth_act = true
            self.seventeenth_act = true
        end)
    end
    if self.sixteenth_act then -- Act #16: BEFORE Moving back to own field.
        self.sixteenth_act = false -- Act #16 executes once.
        if self.rooted > 0 then
            self.idle_speed = self.base_idle_speed
            increment_pattern(self) -- Skips to next move.
        else
            self.original_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            if self:get_tile() ~= self.original_tile then
                self.original_tile:remove_entity_by_id(self:get_id())
                self.original_tile = nil
            end
            if self.change_facing == 1 then
                self:set_facing(Direction.reverse(self.orig_facing))
                self.change_facing = 2
            elseif self.change_facing == 2 then
                self:set_facing(self.orig_facing)
                self.change_facing = 0
            end
            self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
            self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
            self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
            self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
            self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:hide()
            end
            if self.anim:get_state() ~= "IDLE" then
                self.anim:set_state("IDLE", {
                    {duration=7, state="IDLE_1"},
                    {duration=6, state="IDLE_2"},
                    {duration=6, state="IDLE_3"},
                    {duration=7, state="IDLE_4"},
                    {duration=6, state="IDLE_5"},
                    {duration=6, state="IDLE_6"},
                })
            end
            --self.prev_tile = self:get_tile()
            --[[
            local orig_tile = self:get_tile()
            self.prev_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            self.prev_tile:remove_entity_by_id(self:get_id())
            self.prev_tile = orig_tile
            self.prev_tile:add_entity(self)
            self.prev_tile = nil
            ]]
            local tile = choose_move(self, self:get_field())
            if not tile or not self.can_move_to_func(self.next_tile) then
                tile = self:get_tile()
            end
            self.next_tile = tile
            self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                afterimage_spawner(self, self:get_tile(), self.next_tile)
                self.slide_started = true
            end)
        end
    end
    if self.seventeenth_act then -- Act #17: Moving back to own field.
        if self.next_tile then
            self.next_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
            self.next_tile:reserve_entity_by_id(self:get_id())
        end
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            local orig_tile = self.next_tile
            self.next_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            self.next_tile:remove_entity_by_id(self:get_id())
            self.next_tile = orig_tile
            self.next_tile:add_entity(self)
            --self.next_tile = nil
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal()
            end
            if self:get_tile():get_team() == self:get_team() then
                self:share_tile(false)
            end
            self.slide_started = false
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.idle_speed = 13
            increment_pattern(self) -- Next move.
        end
    end
end

-- The "Hell's Rolling" move function.
-- Function by K1rbYat1Na.
function hellsrolling(self)
    if self.first_act then
        self.first_act = false
        if self.skip_hellsrolling then
            self.skip_hellsrolling = false
            self.idle_speed = self.base_idle_speed*2
            increment_pattern(self)
        else
            local frames = {}
            frames[1] = {duration=5, state="SHOOTINGBUSTER_1"}
            for i=2, 6, 2 do
                frames[i] = {duration=5, state="HOLDINGORBS_1"}
            end
            for i=3, 7, 2 do
                frames[i] = {duration=5, state="HOLDINGORBS_2"}
            end
            frames[8] = {duration=3, state="ORBSCHARGE_1"}
            for i=9, 59, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_2"}
            end
            for i=10, 60, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_2"}
            end
            for i=11, 61, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_2"}
            end
            for i=12, 62, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_2"}
            end
            for i=13, 63, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_2"}
            end
            for i=14, 64, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_3"}
            end
            for i=15, 65, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_3"}
            end
            for i=16, 56, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_3"}
            end
            for i=17, 57, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_3"}
            end
            for i=18, 58, 10 do
                frames[i] = {duration=1, state="ORBSCHARGE_3"}
            end
            frames[66] = {duration=3, state="ORBSCHARGE_3"}
            frames[67] = {duration=5, state="SHOOTINGBUSTER_1"}
            self.anim:set_state("HELLSROLLING", frames)
            self.anim:on_frame(2, function()
                self.orbs_anim:set_state("1")
                self.orbs_anim:set_playback(Playback.Loop)
                self.orbs_anim:refresh(self.orbs)
                Engine.play_audio(ORBS_AUDIO, AudioPriority.Low)
            end)
            self.anim:on_frame(8, function()
                self.orbs_anim:set_state("0")
                self.orbs_anim:set_playback(Playback.Loop)
                self.orbs_anim:refresh(self.orbs)
            end)
            self.anim:on_frame(20, function()
                self.counterable_component.timer = 16+2 -- Makes Forte counterable for 16+2 frames.
            end)
            self.anim:on_frame(21, function()
                create_hellsrolling(self, self:get_tile(), "1") -- Creates a Hell's rolling ring that travels the upper line.
            end)
            self.anim:on_frame(50, function()
                self.counterable_component.timer = 16+2 -- Makes Forte counterable for 16+2 frames.
            end)
            self.anim:on_frame(51, function()
                create_hellsrolling(self, self:get_tile(), "2") -- Creates a Hell's rolling ring that travels the lower line.
            end)
            self.anim:on_complete(function()
                self.idle_speed = self.base_idle_speed*2
                increment_pattern(self) -- Next move.
            end)
        end
    end
end

-- The "Darkness Overload" move function.
-- Function by K1rbYat1Na.
function darknessoverload(self)
    if self.first_act then
        self.first_act = false
        --self.moving_to_enemy_tile = true
        local tile = choose_move_for_darknessoverload(self, self:get_field())
        if not tile or not self.can_move_to_func(tile) then
            self.idle_speed = self.idle_speed*2+15
            increment_pattern(self)
        end
        local frames = {}
        frames[1] = {duration=5, state="SHOOTINGBUSTER_1"}
        for i=2, 6, 2 do
            frames[i] = {duration=5, state="HOLDINGORBS_1"}
        end
        for i=3, 7, 2 do
            frames[i] = {duration=5, state="HOLDINGORBS_2"}
        end
        self.anim:set_state("DARKNESSOVERLOAD1", frames)
        self.anim:on_frame(2, function()
            self.orbs_anim:set_state("1")
            self.orbs_anim:set_playback(Playback.Loop)
            self.orbs_anim:refresh(self.orbs)
            Engine.play_audio(ORBS_AUDIO, AudioPriority.Low)
        end)
        self.anim:on_complete(function()
            self.second_act = true
        end)
    end
    if self.second_act then
        self.second_act = false
        self.use_flickering = true -- Turns ON the flickering effect for Forte's sprite.
        self:share_tile(true)
        self:toggle_hitbox(false) -- Disables Forte's hitbox, so he can't take damage while moving.
        self:set_offset(self:get_offset().x, self:get_offset().y-400) -- Offsets the sprite up in order to hide HP.
        self:set_texture(FORTE_MOVE_TEXTURE, true) -- Sets alternative texture for the idle animation.
        self:set_palette(FORTE_MOVE_PALETTE) -- Sets alternative palette for the idle animation.
        if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
        else
            self.blackbarrier:hide()
        end
        self.anim:set_state("DARKNESSOVERLOAD2", {
            {duration=5, state="HOLDINGORBS_1"},
            {duration=5, state="HOLDINGORBS_2"},
        })
        self.anim:set_playback(Playback.Loop)
        self.orbs_anim:set_state("0")
        self.orbs_anim:set_playback(Playback.Loop)
        self.orbs_anim:refresh(self.orbs)
        self.prev_tile = self:get_tile()
        self.original_tile = self.prev_tile
        local tile = choose_move_for_darknessoverload(self, self:get_field())
        if not tile or not self.can_move_to_func(tile) then
            self.idle_speed = self.idle_speed*2
            increment_pattern(self)
        else
            self.next_tile = tile
            self:slide(self.next_tile, frames(self.move_frames+4), frames(1), ActionOrder.Voluntary, function()
                afterimage_spawner(self, self:get_tile(), self.next_tile)
                self.slide_started = true
                self.third_act = true
            end)
        end
    end
    if self.third_act then
        if self.original_tile then
            self.original_tile:reserve_entity_by_id(self.reserving_obstacle:get_id())
            self.original_tile:reserve_entity_by_id(self:get_id())
        end
        if self:get_tile() == self.next_tile and not self:is_sliding() and self.slide_started then
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:reveal()
            end
            self.slide_started = false
            self:set_offset(self:get_offset().x, self:get_offset().y+400)
            self.third_act = false
            self.fourth_act = true
        end
    end
    if self.fourth_act then
        self.fourth_act = false
        self.use_flickering = false -- Turns OFF the flickering effect for Forte's sprite.
        self:toggle_hitbox(true) -- Enables Forte's hitbox, so he can't take damage while not moving.
        self:set_texture(FORTE_TEXTURE, true) -- Sets default texture for the idle animation.
        self:set_palette(self:get_base_palette()) -- Sets default palette for the idle animation.
        local frames = {}
        frames[1] = {duration=5, state="HOLDINGORBS_1"}
        frames[2] = {duration=4, state="HOLDINGORBS_2"}
        frames[3] = {duration=1, state="HOLDINGORBS_2"}
        frames[4] = {duration=3, state="ORBSCHARGE_1"}
        for i=5, 15, 2 do
            frames[i] = {duration=5, state="ORBSCHARGE_2"}
        end
        for i=6, 14, 2 do
            frames[i] = {duration=5, state="ORBSCHARGE_3"}
        end
        frames[16] = {duration=4, state="ORBSCHARGE_3"}
        frames[17] = {duration=5, state="SHOOTINGBUSTER_1"}
        self.anim:set_state("DARKNESSOVERLOAD3", frames)
        self.anim:on_frame(1, function()
            self.orbs_anim:set_state("1")
            self.orbs_anim:set_playback(Playback.Loop)
            self.orbs_anim:refresh(self.orbs)
        end)
        self.anim:on_frame(3, function()
            self.counterable_component.timer = 10+2 -- Makes Forte countarable for 10+2 frames.
        end)
        self.anim:on_frame(4, function()
            if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
            else
                self.blackbarrier:delete()
            end
            self.orbs_anim:set_state("0")
            self.orbs_anim:set_playback(Playback.Loop)
            self.orbs_anim:refresh(self.orbs)
        end)
        self.anim:on_frame(5, function()
            create_darknessoverload(self, self:get_tile())
        end)
        self.anim:on_complete(function()
            self.original_tile:remove_entity_by_id(self.reserving_obstacle:get_id())
            if self:get_tile() ~= self.original_tile then
                self.original_tile:remove_entity_by_id(self:get_id())
                self.original_tile = nil
            end
            if self.can_use_blackbarrier then
                Engine.play_audio(BLACKBARRIER_AUDIO, AudioPriority.Low)
                if self.blackbarrier == nil or self.blackbarrier:is_deleted() then
                    self.blackbarrier = create_blackbarrier(self)
                end
            end
            self.idle_speed = 0
            increment_pattern(self)
        end)
    end
end

-- The "Find Valid More Location" function.
-- Function by Alrysc.
function find_valid_move_location(self)
	local target_tile
	local field = self:get_field()

	local tiles = field:find_tiles(function(tile)
		return self.can_move_to_func(tile)
	end)
  
	debug_print(#tiles)
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

-- The "Choose Enemy" function.
-- Function by Alrysc, edited by K1rbYat1Na.
function choose_enemy(self, field)
    local team = self:get_team()
    local target = field:find_characters(function(c)
        return c:get_team() ~= team
    end)
    if not target[1] then 
        debug_print("No targets")
        return nil
    end
    return target[1]
end

-- The "Choose Move" function.
-- Function by Alrysc, edited by K1rbYat1Na.
function choose_move(self, field)
    local team = self:get_team()
    local tiles = field:find_tiles(function(tile)
        return self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) and tile:get_team() == self:get_team() and tile ~= self:get_tile()
    end)
    if #tiles == 0 then 
        return self:get_tile()
    end
    debug_print("Found ", #tiles, " possible tiles")
    return tiles[math.random(1, #tiles)]
end

-- The "Choose Move For ShootingBuster" function.
-- Chooses a random far tile of his field, so Forte can use Shooting Buster.
-- Function by K1rbYat1Na.
function choose_move_for_shootingbuster(self, field)
    local tiles = field:find_tiles(function(tile)
        return self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) and ((self:get_facing() == Direction.Left and tile:x() >= field:width()-1) or (self:get_facing() == Direction.Right and tile:x() <= 2))
    end)
    if #tiles == 0 then 
        return self:get_tile()
    end
    debug_print("Found ", #tiles, " possible tiles")
    return tiles[math.random(1, #tiles)]
end

-- The "Choose Move to Enemy Front' function.
-- Chooses the tile in front of the first enemy.
-- Function by K1rbYat1Na.
function choose_move_to_enemy_front(self, field)
    local enemy = choose_enemy(self, field) -- Gets the first enemy.
    if enemy == nil then -- If can't get the first enemy.
        return nil
    end
    local enemy_tile = enemy:get_tile() -- Gets the first enemy's current tile.
    local tile = enemy_tile:get_tile(enemy:get_facing(), 1) -- Gets the tile in front of the first enemy.
    if self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) then
    else
        return nil
    end
    --debug_print("Found ", #tile, " possible tile")
    return tile
end

-- The "Choose Move to Enemy Back" function.
-- Chooses the tile behind the first enemy.
-- Function by K1rbYat1Na.
function choose_move_to_enemy_back(self, field)
    local enemy = choose_enemy(self, field) -- Gets the first enemy.
    if enemy == nil then
        return nil
    end
    local enemy_tile = enemy:get_tile()
    local tile = enemy_tile:get_tile(enemy:get_facing_away(), 1)
    if self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) then
    else
        return nil
    end
    --debug_print("Found ", #tile, " possible tile")
    return tile
end

-- The "Choose Move To Center Back" function.
-- Chooses the central back tile of own field.
-- Function by K1rbYat1Na.
function choose_move_to_center_back(self, field)
    local tile = nil
    if self:get_facing() == Direction.Right then
        tile = field:tile_at(1, 2)
    else
        tile = field:tile_at(field:width(), 2)
    end
    if self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) then
    else
        return nil
    end
    --debug_print("Found ", #tile, " possible tile")
    return tile
end

-- The "Choose Move For DarknessOverload" function.
-- Chooses the tile of enemy field, so Forte can use Darkness Overload.
-- Function by K1rbYat1Na.
function choose_move_for_darknessoverload(self, field)
    local tile = nil
    if self:get_facing() == Direction.Right then
        tile = field:tile_at(field:width()-2, 2)
    else
        tile = field:tile_at(3, 2)
    end
    if self.can_move_to_func(tile) and tile:is_walkable() and not check_obstacles(tile, self) then
    else
        return nil
    end
    --debug_print("Found ", #tile, " possible tile")
    return tile
end

-- The "Reconstruct Pattern" function.
-- Function by Alrysc, edited by K1rbYat1Na.
function reconstruct_pattern(self)
    local pattern = {} -- Sets a pattern table.
    local states = self.states -- Gets Forte's states.
    local rnd_moveset_number = nil
    repeat
        rnd_moveset_number = math.random(1,5) -- Generates a random number that determines which movesets will be used in the pattern.
    until rnd_moveset_number ~= self.rnd_moveset_number
    --[[
        1 = Y N N
        2 = Y Y N
        3 = Y Y Y
        4 = Y N Y
        5 = N Y Y
    ]]--
    -- Moveset #1: Moving 1-6 times, then Shooting Buster.
    if rnd_moveset_number == 1 or rnd_moveset_number == 2 or rnd_moveset_number == 3 or rnd_moveset_number == 4 or not self.attacked_once then
        local moves = math.random(1,4)
        for i=1, moves do
            table.insert(pattern, states.move)
            table.insert(pattern, states.idle)
        end
        table.insert(pattern, states.move)
        table.insert(pattern, states.idle)
        table.insert(pattern, states.move_for_shootingbuster)
        table.insert(pattern, states.idle)
        table.insert(pattern, states.shootingbuster)
        table.insert(pattern, states.idle)
    end
    -- Moveset #2: Dark Arm Blade once, then Hell's Rolling.
    if rnd_moveset_number == 2 or rnd_moveset_number == 3 or rnd_moveset_number == 5 or not self.attacked_once then
        if not self.attacked_once then
            self.attacked_once = true
        end
        table.insert(pattern, states.darkarmblade1)
        table.insert(pattern, states.idle)
        table.insert(pattern, states.move_for_hellsrolling)
        table.insert(pattern, states.idle)
        table.insert(pattern, states.hellsrolling)
        table.insert(pattern, states.idle)
    end
    -- Moveset #3: Dark Arm Blade thrice, then Darkness Overload, them moving once.
    if rnd_moveset_number == 3 or rnd_moveset_number == 4 or rnd_moveset_number == 5 then
        table.insert(pattern, states.darkarmblade3)
        table.insert(pattern, states.idle)
        table.insert(pattern, states.darknessoverload)
        table.insert(pattern, states.move)
        table.insert(pattern, states.idle)
    end

    self.pattern = pattern -- Sets the pattern.
end

-- The "Increment Pattern" function.
-- Function by Alrysc, edited by K1rbYat1Na.
function increment_pattern(self)
    debug_print("Pattern increment")

    self.first_act = true -- Resets Act #1.
    self.second_act = false -- Resets Act #2.
    self.third_act = false -- Resets Act #3.
    self.fourth_act = false -- Resets Act #4.
    self.fifth_act = false -- Resets Act #5.
    self.sixth_act = false -- Resets Act #6.
    self.seventh_act = false -- Resets Act #7.
    self.eighth_act = false -- Resets Act #8.
    self.ninth_act = false -- Resets Act #9.
    self.tenth_act = false -- Resets Act #10.
    self.eleventh_act = false -- Resets Act #11.
    self.twelfth_act = false -- Resets Act #12.
    self.thirteenth_act = false -- Resets Act #13.
    self.fourteenth_act = false -- Resets Act #14.
    self.fifteenth_act = false -- Resets Act #15.
    self.sixteenth_act = false -- Resets Act #16.
    self.seventeenth_act = false -- Resets Act #17.
    self.darkarmblade_behind = false -- Resets the variable.
    self.darkarmblade_tile1 = nil -- Resets the tile for Dark Arm Blade #1 (Dark Arm Blade thrice).
    self.darkarmblade_tile2 = nil -- Resets the tile for Dark Arm Blade #2 (Dark Arm Blade thrice).
    self.darkarmblade_tile3 = nil -- Resets the tile for Dark Arm Blade #3 (Dark Arm Blade thrice).

    self.state_done = false
    self.pattern_index = self.pattern_index + 1
    if self.pattern_index > #self.pattern then 
        reconstruct_pattern(self)
        debug_print("Reconstructed pattern")
        self.pattern_index = 1
    end
    local next_state = self.pattern[self.pattern_index]
    self.state = next_state
    debug_print("Moving to state named ", next_state.name)

    if next_state == self.states.start_sub_pattern then 
        self.in_sub_pattern = true
        increment_pattern(self)
    end

    if next_state == self.states.finish_sub_pattern then 
        self.in_sub_pattern = false
        increment_pattern(self)
    end

    debug_print("Changing to "..self.pattern_index..", which is "..self.pattern[self.pattern_index].name)
end

-- "Check Obstacles" function.
-- Checks whether the tile has any obstacles on it.
-- Function by Alrysc.
function check_obstacles(tile, self)
    local ob = tile:find_obstacles(function(o)
        return o:get_health() > 0 
    end)
    return #ob > 0 
end

-- "Check Characters" function.
-- Checks whether the tile has any UNFRIENDLY characters on it.
-- Function by Alrysc.
function check_characters(tile, self)
    local characters = tile:find_characters(function(c)
        return c:get_id() ~= self:get_id() and c:get_team() ~= self:get_team()
    end)
    return #characters > 0
end

-- "Check Characters True" function.
-- Checks whether the tile has any characters on it.
-- Function by K1rbYat1Na.
function check_characters_true(tile, self)
    local characters = tile:find_characters(function(c)
        return true
    end)
    return #characters > 0
end