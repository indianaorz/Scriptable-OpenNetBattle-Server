local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name="Canodumb",
        hp=50,
        damage=10,
        palette=_folderpath.."battle_v1.palette.png",
        height=55
    }
    if character:get_rank() == Rank.V1 then
        character_info.name = "Cannodumb"
    end
    if character:get_rank() == Rank.V2 then
        character_info.hp = 80
        character_info.damage = 30
        character_info.palette=_folderpath.."battle_v2.palette.png"
    elseif character:get_rank() == Rank.V3 then
        character_info.hp = 140
        character_info.damage = 60
        character_info.palette=_folderpath.."battle_v3.palette.png"
    elseif character:get_rank() == Rank.SP then
        character_info.hp = 190
        character_info.damage = 100
        character_info.palette=_folderpath.."battle_sp.palette.png"
    end
    shared_package_init(character,character_info)
end
