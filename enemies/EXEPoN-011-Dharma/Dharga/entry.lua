local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Dharga",
        hp = 120,
        damage = 50,
        palette = _folderpath.."V2.png",
        height = 44,
        move_speed = 30,
        move_time = 30,
        puck_speed = 17,
    }
    shared_package_init(character, character_info)
end
