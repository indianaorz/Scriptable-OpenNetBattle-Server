local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Dhardara",
        hp = 170,
        damage = 70,
        palette = _folderpath.."V3.png",
        height = 44,
        move_speed = 22,
        move_time = 22,
        puck_speed = 12,
    }
    shared_package_init(character, character_info)
end
