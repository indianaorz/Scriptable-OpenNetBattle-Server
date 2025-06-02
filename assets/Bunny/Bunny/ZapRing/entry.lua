local DAMAGE = 20

local RABIRING_TEXTURE = Engine.load_texture(_folderpath .. "rabiring.png")
local RABIRING_ANIMPATH = _folderpath .. "rabiring.animation"
local RABIRING_AUDIO = Engine.load_audio(_folderpath .. "rabiring.ogg")

local EFFECT_TEXTURE = Engine.load_texture(_folderpath .. "effect.png")
local EFFECT_ANIMPATH = _folderpath .. "effect.animation"
local DAMAGE_AUDIO = Engine.load_audio(_folderpath .. "hitsound.ogg")

local chip = {}

function package_init(package)
    package:declare_package_id("com.claris.k1rbyat1na.card.EXE3-055-RabiRing1")
    package:set_icon_texture(Engine.load_texture(_folderpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath .. "preview.png"))
    package:set_codes({ "A", "M", "P", "Q", "S", "*" })

    local props = package:get_card_props()
    props.shortname = "ZapRing1"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Elec
    props.description = "Pralyzing electric ring atk!"
    props.long_description = "An electric ring attack! Paralyzes your target for a while!"
    props.can_boost = true
    props.card_class = CardClass.Standard
    props.limit = 5
end

chip.card_create_action = function(actor, props)
    -- Bunny uses attack animation and doesn't need a buster.
    local anim = actor:get_animation()
    anim:set_state("ATTACK")
    local field = actor:get_field()
    local team = actor:get_team()
    local direction = actor:get_facing()
    anim:on_complete(function()
        create_ring(actor, props, team, direction, 4, 0, field, actor:get_tile(direction, 1))
        actor:get_animation():set_state("ATTACK_END")
        actor:get_animation():on_complete(function()
            actor.set_state(1)
            actor.move_counter = 0
        end)
    end)
end

function create_ring(user, props, team, direction, frames_count1, frames_count2, field, tile)
    local spell = Battle.Spell.new(team)
    spell:set_offset(0.0, -16.0)
    spell.slide_started = false

    spell:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Stun | Hit.Flinch,
            props.element,
            user:get_context(),
            Drag.None
        )
    )

    local sprite = spell:sprite()
    sprite:set_texture(RABIRING_TEXTURE, true)
    sprite:set_layer(-3)

    local anim = spell:get_animation()
    anim:load(RABIRING_ANIMPATH)
    anim:set_state("0")

    spell.update_func = function(self, dt)
        self:get_current_tile():attack_entities(self)

        if self:is_sliding() == false then
            if self:get_current_tile():is_edge() and self.slide_started then
                self:delete()
            end

            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(frames_count1), frames(frames_count2), ActionOrder.Voluntary,
                function()
                    ref.slide_started = true
                end
            )
        end
    end

    spell.attack_func = function(self, other)
        Engine.play_audio(Engine.load_audio(_folderpath .. "hitsound.ogg"), AudioPriority.High)
        create_effect(EFFECT_TEXTURE, EFFECT_ANIMPATH, "ELEC", math.random(-30, 30), math.random(-30, 30), field,
            spell:get_current_tile())
    end

    spell.collision_func = function(self, other)
        self:erase()
    end

    spell.delete_func = function(self)
    end

    spell.can_move_to_func = function(tile)
        return true
    end

    Engine.play_audio(RABIRING_AUDIO, AudioPriority.High)

    field:spawn(spell, tile)

    return spell
end

function create_effect(effect_texture, effect_animpath, effect_state, offset_x, offset_y, field, tile)
    local hitfx = Battle.Artifact.new()
    hitfx:set_facing(Direction.Right)
    hitfx:set_texture(effect_texture, true)
    hitfx:set_offset(offset_x, offset_y)
    local hitfx_sprite = hitfx:sprite()
    hitfx_sprite:set_layer(-9)
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

return chip
