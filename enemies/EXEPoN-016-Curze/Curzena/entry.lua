local shared_package_init = include("../shared/entry.lua")

function package_init(character)
    local character_info = {
        name = "Curzena",
        hp = 120,
        damage = 70,
        palette = _folderpath.."V2.png",
        move_speed = 45
    }
    shared_package_init(character, character_info)
end