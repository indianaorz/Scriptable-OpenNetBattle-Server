local PROJ_TEXTURE = Engine.load_texture(_folderpath .. "rabiring.png")
local PROJ_ANIM = _folderpath .. "rabiring.animation"
local PROJ_AUDIO = Engine.load_audio(_folderpath .. "rabiring.ogg")
local EFFECT_TEXTURE = Engine.load_texture(_folderpath .. "effect.png")
local EFFECT_ANIM = _folderpath .. "effect.animation"
local HIT_AUDIO = Engine.load_audio(_folderpath .. "hitsound.ogg")

local projectile = {}

projectile.create = function(user, damage)
    local team = user:get_team()
    local direction = user:get_facing()
    local field = user:get_field()
    local tile = user:get_tile(direction, 1)

    local spell = Battle.Spell.new(team)
    spell:set_offset(0, -16)
    spell.slide_started = false
    spell:set_hit_props(
        HitProps.new(
            damage,
            Hit.Impact | Hit.Flinch,
            Element.None,
            user:get_context(),
            Drag.None
        )
    )

    local sprite = spell:sprite()
    sprite:set_texture(PROJ_TEXTURE, true)
    sprite:set_layer(-3)

    local anim = spell:get_animation()
    anim:load(PROJ_ANIM)
    anim:set_state("0")

    spell.update_func = function(self, dt)
        self:get_current_tile():attack_entities(self)
        if not self:is_sliding() then
            if self:get_current_tile():is_edge() and self.slide_started then
                self:erase()
                return
            end
            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(4), frames(0), ActionOrder.Voluntary, function() ref.slide_started = true end)
        end
    end

    spell.attack_func = function(self, other)
        Engine.play_audio(HIT_AUDIO, AudioPriority.High)
        local fx = Battle.Artifact.new()
        fx:set_facing(Direction.Right)
        fx:set_texture(EFFECT_TEXTURE, true)
        local fx_anim = fx:get_animation()
        fx_anim:load(EFFECT_ANIM)
        fx_anim:set_state("ELEC")
        fx_anim:refresh(fx:sprite())
        fx_anim:on_complete(function() fx:erase() end)
        field:spawn(fx, self:get_current_tile())
    end

    spell.collision_func = function(self, other)
        self:erase()
    end

    spell.delete_func = function(self) end

    spell.can_move_to_func = function(tile) return true end

    Engine.play_audio(PROJ_AUDIO, AudioPriority.High)
    field:spawn(spell, tile)
    return spell
end

return projectile
