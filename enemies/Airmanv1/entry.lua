local package_id = "com.louise_AirManV1"
local character_id = "com.louise_enemy_AirManV1"

function package_requires_scripts()
  Engine.define_character(character_id, _modpath.."AirManV1")
end

function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("AirMan")
  package:set_description("AirMan remastered!")
  package:set_speed(1)
  package:set_attack(70)
  package:set_health(1200)
  package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
local texPath = _modpath.."background.png"
local animPath = _modpath.."background.animation"
mob:set_background(texPath, animPath, -0.5, -0.5)
mob:stream_music(_modpath.."airman.mid", 0, 0)

local spawner = mob:create_spawner(character_id, Rank.V1)
spawner:spawn_at(5, 2)
end
