local package_prefix = "OFC"
local package_gid = "EXEPoN-016"
local package_name = "Curze"
local package_name2 = "Curzena"
local package_name3 = "Curzed"

local package_id = "com."..package_prefix..".mob."..package_gid.."-"..package_name
local character_id = "com."..package_prefix..".char."..package_gid.."-"

function package_requires_scripts()
    Engine.define_character(character_id..package_name, _modpath..package_name)
    Engine.define_character(character_id..package_name2, _modpath..package_name2)
    Engine.define_character(character_id..package_name3, _modpath..package_name3)
end

function package_init(package) 
    print('package init for '..package_id)
    package:declare_package_id(package_id)
    package:set_name(package_name.." (EXEPoN)")
    package:set_description("Test fight with the "..package_name.." family from EXEPoN")
    package:set_speed(1)
    package:set_attack(60)
    package:set_health(80)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob) 
    --can setup backgrounds, music, and field here
    local test_spawner1 = mob:create_spawner(character_id..package_name,Rank.V1)
    test_spawner1:spawn_at(4, 1)
    local test_spawner2 = mob:create_spawner(character_id..package_name2,Rank.V1)
    test_spawner2:spawn_at(5, 2)
    local test_spawner3 = mob:create_spawner(character_id..package_name3,Rank.V1)
    test_spawner3:spawn_at(6, 3)
    mob:stream_music(_modpath.."Pon_Virus_busting.ogg", 0, 46334)
end


