local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Dharma",
        hp = 80,
        damage = 30,
        palette = _folderpath.."V1.png",
        height = 44,
        move_speed = 38,
        move_time = 38,
        puck_speed = 22,
    }
    if character:get_rank() == Rank.SP then
        character_info.hp = 200
        character_info.damage = 100
        character_info.palette = _folderpath.."SP.png"
        character_info.move_speed = 14
        character_info.move_time = 14
        character_info.puck_speed = 7
    end
    shared_package_init(character, character_info)
end
