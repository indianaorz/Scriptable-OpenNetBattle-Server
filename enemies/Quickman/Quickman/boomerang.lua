local BOOMERANG_SOUND = Engine.load_audio(_folderpath .. "boomer.ogg")
local BOOMERANG_SPRITE = Engine.load_texture(_folderpath .. "quickboomer.png")
local BOOMERANG_ANIM = _folderpath .. "quickboomer.animation"
local effects_texture = Engine.load_texture(_modpath .. "effect.png")
local effects_anim = _modpath .. "effect.animation"
local battle_helpers = include("battle_helpers.lua")

---@class Blade
local helper = {}
-- from quickM
local states = { DEFAULT = 1, MOVE = 2, BMRNG = 3, SWORD = 4 }

helper.throw = function(user, damage)

    local anim = user:get_animation()
    anim:set_state("BOOMERANG")
    local hit_props = HitProps.new(
        damage,
        Hit.Impact | Hit.Flinch,
        Element.Sword,
        user:get_context(),
        Drag.None
    )

    anim:on_frame(1, function()
        user:toggle_counter(true)
    end)


    anim:on_frame(4, function()
        user:toggle_counter(false)
        Engine.play_audio(BOOMERANG_SOUND, AudioPriority.High)
        boomerang(user, hit_props, false)
    end)



    anim:on_complete(function()
        if (user.boomerangs <= 0) then
            if (user:get_rank() ~= Rank.V1 and user:get_health() < user.max_hp / 2) then
                user.set_state(states.SWORD)
            else
                user.set_state(states.DEFAULT)
            end
        else
            user.set_state(states.BMRNG)
        end
    end)

end

function Tiletostring(tile)
    return "Tile: [" .. tostring(tile:x()) .. "," .. tostring(tile:y()) .. "]"
end

---Boomerang!
---@param user Entity
function boomerang(user, hit_props)
    local field = user:get_field()
    ---@class Spell
    local spell = Battle.Obstacle.new(user:get_team())
    spell:set_health(10)
    local spell_animation = spell:get_animation()
    local start_tile = user:get_tile(user:get_facing(), 1)
    -- Spell Hit Properties

    -- YOYO DEFENSE
    spell.defense_rule = Battle.DefenseRule.new(0, DefenseOrder.Always)
    local defense_texture = Engine.load_texture(_folderpath .. "guard_hit.png")
    local defense_animation = _folderpath .. "guard_hit.animation"
    local defense_audio = Engine.load_audio(_folderpath .. "tink.ogg")
    spell.defense_rule.can_block_func = function(judge, attacker, defender)
        local attacker_hit_props = attacker:copy_hit_props()
        if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
            --cant block breaking hits
            return
        end
        judge:block_impact()
        judge:block_damage()
        local artifact = Battle.Spell.new(spell:get_team())
        artifact:set_texture(defense_texture)
        local anim = artifact:get_animation()
        anim:load(defense_animation)
        anim:set_state("DEFAULT")
        anim:refresh(artifact:sprite())
        anim:on_complete(function()
            artifact:erase()
        end)
        spell:get_field():spawn(artifact, spell:get_tile())
        Engine.play_audio(defense_audio, AudioPriority.High)
    end
    spell:add_defense_rule(spell.defense_rule)

    --#end yoyo defense

    local figure8 = false
    if (user:get_rank() ~= Rank.V1 and math.random(1, 3) == 1) then
        figure8 = true
    end

    spell:set_hit_props(hit_props)
    spell:set_facing(user:get_facing())
    spell:set_shadow(Shadow.Small)
    spell:show_shadow(true)
    spell_animation:load(BOOMERANG_ANIM)
    spell_animation:set_state("DEFAULT")
    spell_animation:set_playback(Playback.Loop)
    spell:set_texture(BOOMERANG_SPRITE)
    spell_animation:refresh(spell:sprite())
    spell:sprite():set_layer(-5)
    -- Starting direction is user's facing
    spell.xdirection = user:get_facing()
    spell.ydirection = Direction.Down
    if (user:get_tile():y() == 3) then
        spell.ydirection = Direction.Up
    end
    if not figure8 then
        spell.ydirection = Direction.None
    end
    spell.userfacing = user:get_facing()
    spell.returning = false
    spell.boomer_speed = 6
    local joineddirection = Direction.join(spell.xdirection, spell.ydirection)
    spell.next_tile = start_tile:get_tile(joineddirection, 1)
    spell.update_func = function(self, dt)
        if (spell.returning and spell:get_tile() == start_tile) then
            spell:erase()
        end
        if (is_edgeX(spell.next_tile)) then
            if (spell:get_tile():get_team() == user:get_team()) then
                spell:erase()
            else
                spell.xdirection = Direction.reverse(spell.xdirection)
                spell.returning = true
            end
        end
        if (is_edgeY(spell.next_tile)) then
            spell.ydirection = Direction.reverse(spell.ydirection)
        end
        spell:slide(spell.next_tile, frames(spell.boomer_speed), frames(0), ActionOrder.Voluntary, nil)
        local joineddirection = Direction.join(spell.xdirection, spell.ydirection)
        spell.next_tile = spell:get_current_tile():get_tile(joineddirection, 1)
        spell:get_current_tile():attack_entities(self)
    end
    spell.collision_func = function(self, other)
        spawn_visual_artifact(self:get_field(), self:get_tile(), effects_texture, effects_anim, "8"
            , 0, 0)
        spell:erase()
    end
    spell.attack_func = function(self, other)

    end
    spell.delete_func = function(self)
        self:erase()
    end
    spell.can_move_to_func = function(tile)
        return true
    end
    field:spawn(spell, start_tile)
end

function is_edgeX(tile)
    return tile == nil or tile:x() < 1 or tile:x() > 6
end

function is_edgeY(tile)
    return tile == nil or tile:y() < 1 or tile:y() > 3
end

-- This function spawns a visual effect that will remove itself once the effect animation completes.
function spawn_visual_artifact(field, tile, texture, animation_path, animation_state, position_x,
                               position_y)
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(texture, true)
    local anim = visual_artifact:get_animation()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:sprite():set_offset(position_x, position_y)
    anim:refresh(visual_artifact:sprite())
    field:spawn(visual_artifact, tile:x(), tile:y())
end

return helper
