local shared_package_init = include("./character.lua")

--custom properties:
-- max_boomerangs: amount of boomerangs Quickman will throw before idling again.
function package_init(character)
    local character_info = {
        name = "Quickman",
        hp = 600,
        damage = 40,
        palette = _folderpath .. "base.png",
        height = 44,
        element = Element.None,
        max_boomerangs = 1
    }
    if character:get_rank() == Rank.V2 then
        character_info.hp = 900
        character_info.damage = 80
        character_info.sword_damage = 120
        character_infomax_boomerangs = 2
        character_infoname = "QuickmanV"
    end
    if character:get_rank() == Rank.V3 then
        character_info.hp = 1200
        character_info.damage = 120
        character_info.sword_damage = 180
        character_info.max_boomerangs = 2
        character_info.name = "QuickmanV"
    end
    if character:get_rank() == Rank.SP then
        character_info.hp = 1600
        character_info.damage = 200
        character_info.sword_damage = 280
        character_info.palette = _folderpath .. "SP.png"
        character_info.max_boomerangs = 3
        character_info.name = "Quickman"
    end
    if character:get_rank() == Rank.NM then
        character_info.hp = 2500
        character_info.damage = 280
        character_info.sword_damage = 400
        character_info.palette = _folderpath .. "DS.png"
        character_info.max_boomerangs = 3
        character_info.name = "Quickman"
    end
    shared_package_init(character, character_info)
end
