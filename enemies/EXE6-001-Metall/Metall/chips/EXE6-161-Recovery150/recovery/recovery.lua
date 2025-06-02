local print_debug = false

local RECOVERY_TEXTURE = Engine.load_texture(_folderpath.."gfx/recovery.grayscaled.png") -- flip for player 2
local RECOVERY_PALETTE = Engine.load_texture(_folderpath.."gfx/palette/recovery.png")
local RECOVERY_ANIMPATH = _folderpath.."gfx/recovery.animation"
local RECOVERY_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE6_108.ogg", true)

local function debug_print(text)
    if print_debug then
        print("[Recovery] "..text)
    end
end

local recovery = {}

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

recovery.card_create_action = function(actor, props)
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
    action:set_lockout(make_async_lockout(0.5))
    local frame_sequence = make_frame_data({{1,0}})
	action:override_animation_frames(frame_sequence)
    action.execute_func = function(self, user)
        local actor = self:get_actor()
        local facing = user:get_facing()
        local field = user:get_field()
        local tile = user:get_tile()
        Engine.play_audio(RECOVERY_AUDIO, AudioPriority.Low)
        local heal_fx = graphic_init("artifact", 0, 0, RECOVERY_TEXTURE, RECOVERY_ANIMPATH, "0", Playback.Once, -999, user, facing, true)
        heal_fx:set_palette(RECOVERY_PALETTE)
        heal_fx:get_animation():on_complete(function() heal_fx:erase() end)
        field:spawn(heal_fx, tile)
        actor:set_health(actor:get_health() + recovery.recover_hp)
	end
    return action
end

return recovery