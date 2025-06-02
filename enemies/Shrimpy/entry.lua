local package_id = "com.louise.Shrimpy"
local character_id = "com.louise.enemy."

-- To spawn this enemy use
-- com.louise.enemy.Shrimpy

function package_requires_scripts()
  Engine.define_character(character_id .. "Shrimpy", _modpath .. "Shrimpy")
end

function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("Shrimpy")
  package:set_description("Shrimpy!")
  package:set_speed(1)
  package:set_attack(30)
  package:set_health(100)
  package:set_preview_texture_path(_modpath .. "preview.png")
end

function package_build(mob)
  local spawner = mob:create_spawner(character_id .. "Shrimpy", Rank.SP)
  spawner:spawn_at(4, 3)

  local spawner = mob:create_spawner(character_id .. "Shrimpy", Rank.SP)
  spawner:spawn_at(5, 2)

  local spawner = mob:create_spawner(character_id .. "Shrimpy", Rank.NM)
  spawner:spawn_at(6, 1)
end
