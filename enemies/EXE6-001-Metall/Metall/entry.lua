local shared_package_init = include("../Metall/character.lua")

function package_init(character)
    local character_info = {
        name = "Metall",
        hp = 40,
        damage = 10,
        damage_shockwave = 10,
        cascade_frame = 5,
        move_delay = 37, -- old: 38
        shockwave_state = "0",
        shockwave_frames = 22,
        can_guard = true,
        replacement_panel = nil
    }
    if character:get_rank() == Rank.V1 then
        character_info.can_guard = false
    end
    if character:get_rank() == Rank.V2 then
        character_info.damage = 20
        character_info.damage_shockwave = 30
        character_info.cascade_frame = 5
        character_info.hp = 80
        character_info.move_delay = 31 -- old: 32
        character_info.shockwave_state = "1"
        character_info.shockwave_frames = 16
    elseif character:get_rank() == Rank.V3 then
        character_info.damage = 40
        character_info.damage_shockwave = 50
        character_info.hp = 120
        character_info.cascade_frame = 4
        character_info.move_delay = 25 -- old: 26
        character_info.shockwave_state = "1"
        character_info.shockwave_frames = 11
    elseif character:get_rank() == Rank.SP then
        character_info.damage = 60
        character_info.damage_shockwave = 70
        character_info.hp = 160
        character_info.cascade_frame = 3
        character_info.move_delay = 19 -- old: 24
        character_info.shockwave_state = "2"
        character_info.shockwave_frames = 6
    elseif character:get_rank() == Rank.Rare1 then
        character_info.damage = 40
        character_info.damage_shockwave = 50
        character_info.hp = 120
        character_info.cascade_frame = 5
        character_info.move_delay = 25 -- old: 26
        character_info.shockwave_state = "1"
        character_info.shockwave_frames = 16
        character_info.replacement_panel = TileState.Cracked
    elseif character:get_rank() == Rank.Rare2 then
        character_info.damage = 80
        character_info.damage_shockwave = 100
        character_info.hp = 180
        character_info.cascade_frame = 3
        character_info.move_delay = 19 -- old: 24
        character_info.shockwave_state = "2"
        character_info.shockwave_frames = 6
        character_info.replacement_panel = TileState.Poison
    end
    shared_package_init(character,character_info)
end