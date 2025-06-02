local shared_package_init = include("../Bunny/character.lua")
local character_id = "com.louise.enemy."
function package_init(character)
    local character_info = {
        name = "TuffBunny",
        hp = 60,
        damage = 60,
        palette = _folderpath .. "palette.png",
        height = 44,
        frames_between_actions = 26,
        fast_hop_frames = 4,
    }

    shared_package_init(character, character_info)
end
