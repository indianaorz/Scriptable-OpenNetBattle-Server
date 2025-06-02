local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Curze",
        hp = 80,
        damage = 60,
        palette = _folderpath.."V1.png",
        move_speed = 60
    }
    if character:get_rank() == Rank.SP then
        character_info.hp = 260
        character_info.damage = 120
        character_info.palette = _folderpath.."SP.png"
        character_info.move_speed = 20
    end
    shared_package_init(character, character_info)
end