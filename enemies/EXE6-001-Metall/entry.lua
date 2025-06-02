local package_id = "com.OFC.mob.EXE6-001-Metall"
local character_id = "com.OFC.char.EXE6-001-Metall"

function package_requires_scripts()
    Engine.define_character(character_id, _modpath.."Metall")
end

function package_init(package)
    --print('package init for '..package_id)
    package:declare_package_id(package_id)
    package:set_name("Metall (EXE6)")
    package:set_description("Test fight with\nthe Metall family\nfrom EXE6")
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
    --can setup backgrounds, music, and field here
    local texPath = _modpath.."08a-urainternet.png"
    local animPath = _modpath.."08-urainternet.animation"
    mob:set_background(texPath, animPath, 0, 0)
    mob:stream_music(_modpath.."exe6-virus.ogg", 3411, 41981)
    local test_spawner = mob:create_spawner(character_id, Rank.SP)
    test_spawner:spawn_at(4, 1)
    test_spawner = mob:create_spawner(character_id, Rank.Rare1)
    test_spawner:spawn_at(5, 2)
    test_spawner = mob:create_spawner(character_id, Rank.Rare2)
    test_spawner:spawn_at(6, 3)
end