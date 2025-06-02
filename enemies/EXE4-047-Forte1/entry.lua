local package_id = "com.OFC.mob.EXE4-047-Forte1"
local character_id = "com.OFC.char.EXE4-047-Forte1"

function package_requires_scripts()
    Engine.define_character(character_id, _modpath.."Forte")
end

function package_init(package)
    package:declare_package_id(package_id)
    package:set_name("Forte (EXE4)")
    package:set_description("Test fight with\nForte\nfrom Rockman EXE4")
    package:set_speed(1)
    package:set_attack(300)
    package:set_health(4000)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
    local texPath = _modpath.."exe4-bg-urainternet.png"
    local animPath = _modpath.."exe4-bg-urainternet.animation"
    mob:set_background(texPath, animPath, 0.0, 0.0)
    mob:stream_music(_modpath.."exe4-boss.ogg", 42253, 80548)
    mob:create_spawner(character_id, Rank.V1):spawn_at(5,2)
end