local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Curzed",
        hp = 160,
        damage = 80,
        palette = _folderpath.."V3.png",
        move_speed = 30
    }
    shared_package_init(character, character_info)
end