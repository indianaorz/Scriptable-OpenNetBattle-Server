local package_id = "com.OFC.mob.EXE4-047-Forte3"
local character_id = "com.OFC.char.EXE4-047-Forte1"

function package_requires_scripts()
    Engine.requires_character(character_id)
end

function package_init(package) 
    package:declare_package_id(package_id)
    package:set_name("Forte XX (EXE4)")
    package:set_description("Test fight with\nForte XX\nfrom Rockman EXE4")
    package:set_speed(3)
    package:set_attack(300)
    package:set_health(4000)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
    local texPath = _modpath.."exe4-bg-blackearth.png"
    local animPath = _modpath.."exe4-bg-blackearth.animation"
    mob:set_background(texPath, animPath, 0.0, 0.0)
    mob:stream_music(_modpath.."exe4-boss.ogg", 42253, 80548)
    mob:create_spawner(character_id, Rank.NM):spawn_at(5,2) -- NM = XX.
end