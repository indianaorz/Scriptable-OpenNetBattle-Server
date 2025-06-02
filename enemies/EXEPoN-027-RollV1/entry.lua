local package_prefix = "OFC"
local package_gid = "EXEPoN-027"
local package_name = "Roll"

local package_id = "com."..package_prefix..".mob."..package_gid.."-"..package_name.."V1"
local character_id = "com."..package_prefix..".char."..package_gid.."-"

function package_requires_scripts()
    Engine.define_character(character_id..package_name, _modpath..package_name)
end

function package_init(package)
    print('package init for '..package_id)
    package:declare_package_id(package_id)
    package:set_name(package_name.." (EXEPoN)")
    package:set_description("Test fight with "..package_name.." from EXEPoN")
    package:set_speed(1)
    package:set_attack(30)
    package:set_health(500)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
    --local texPath = _modpath.."exe4-generic.png"
    --local animPath = _modpath.."exe4-generic.animation"
    local texPath = _modpath.."exepon-fieldbattle.png"
    local animPath = _modpath.."exepon-fieldbattle.animation"
    mob:set_background(texPath, animPath, 0.25, 0.2)
    --mob:stream_music(_modpath.."exepon-boss.ogg", 903, 38377)
    mob:stream_music(_modpath.."phantom_boss.ogg", 0, 38409)
  
    local spawner = mob:create_spawner(character_id..package_name,Rank.V1)
    spawner:spawn_at(5, 2)
end  