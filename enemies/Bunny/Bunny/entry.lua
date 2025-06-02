local shared_package_init = include("./character.lua")
function package_init(character)
    local character_info = {
        name = "Bunny",
        hp = 40,
        damage = 15,
        palette = _folderpath .. "V1.png",
        height = 44,
        frames_between_actions = 34,
        fast_hop_frames = 4,
    }
    if character:get_rank() == Rank.SP then
        character_info.hp = 220
        character_info.damage = 150
        character_info.palette = _folderpath .. "SP.png"
        character_info.frames_between_actions = 14
        character_info.fast_hop_frames = 4
    end
    if character:get_rank() == Rank.NM then
        character_info.damage = 250
        character_info.palette = _folderpath .. "NM.png"
        character_info.hp = 500
        character_info.frames_between_actions = 8
        character_info.fast_hop_frames = 2
    end
    shared_package_init(character, character_info)
end
