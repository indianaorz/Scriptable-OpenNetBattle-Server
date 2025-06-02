local package_id = "com.OFC.mob.EXE3-061-Proto"
local character_id = "com.OFC.char.EXE3-061-Proto"

function package_requires_scripts()
    Engine.define_character(character_id, _modpath.."virus")
end

function package_init(package) 
    package:declare_package_id(package_id)
    package:set_name("Proto (EXE3)")
    package:set_description("Test fight with\nProto\nfrom Rockman EXE3")
    --package:set_description("The Internet is in danger!")
    package:set_speed(1)
    package:set_attack(100)
    package:set_health(2000)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob) 
    local texPath = _modpath.."exe3-bg-proto.png"
    local animPath = _modpath.."exe3-bg-proto.animation"
    mob:set_background(texPath, animPath, 1.173, 0.0)
    mob:stream_music(_modpath.."exe3-final.ogg", 58767, 109745)
    
    mob:create_spawner(character_id, Rank.V1):spawn_at(5,2)
end