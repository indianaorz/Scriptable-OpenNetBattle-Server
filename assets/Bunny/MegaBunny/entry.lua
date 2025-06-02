local shared_package_init = include("../Bunny/character.lua")
local character_id = "com.louise.enemy."
function package_init(character)
    local character_info = {
        name = "MegaBunny",
        hp = 160,
        damage = 90,
        palette = _folderpath .. "palette.png",
        height = 44,
        frames_between_actions = 18,
        fast_hop_frames = 4,
    }

    shared_package_init(character, character_info)
end
