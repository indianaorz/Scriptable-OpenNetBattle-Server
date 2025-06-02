local package_prefix = "OFC"
local package_gid = "EXEPoN-025"
local package_name = "ShadowMan"

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
    package:set_attack(60)
    package:set_health(1000)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
    local texPath = _modpath.."exepon-ipcservernodennou.png"
    local animPath = _modpath.."exepon-ipcservernodennou.animation"
    mob:set_background(texPath, animPath, 0, 0)
    --mob:stream_music(_modpath.."exepon-boss.ogg", 903, 38377)
    mob:stream_music(_modpath.."phantom_boss.ogg", 0, 38409)

    mob:get_field():tile_at(1, 2):set_state(TileState.Grass)
    mob:get_field():tile_at(2, 1):set_state(TileState.Grass)
    mob:get_field():tile_at(2, 2):set_state(TileState.Grass)
    mob:get_field():tile_at(2, 3):set_state(TileState.Grass)
    mob:get_field():tile_at(3, 2):set_state(TileState.Grass)
  
    mob:get_field():tile_at(4, 2):set_state(TileState.Grass)
    mob:get_field():tile_at(5, 1):set_state(TileState.Grass)
    mob:get_field():tile_at(5, 2):set_state(TileState.Grass)
    mob:get_field():tile_at(5, 3):set_state(TileState.Grass)
    mob:get_field():tile_at(6, 2):set_state(TileState.Grass)
  
    local spawner = mob:create_spawner(character_id..package_name,Rank.V1)
    spawner:spawn_at(5, 2)
end  