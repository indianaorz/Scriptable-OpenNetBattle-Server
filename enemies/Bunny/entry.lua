--ID of the package
local package_id = "com.louise.Bunny"
-- prefix of the character id
local character_id = "com.louise.enemy."

function package_requires_scripts()
  --Define characters here.
  Engine.define_character(character_id .. "Bunny", _modpath .. "Bunny")
  Engine.define_character(character_id .. "TuffBunny", _modpath .. "TuffBunny")
  Engine.define_character(character_id .. "MegaBunny", _modpath .. "MegaBunny")
end

--package init.
function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("Bunny")
  package:set_description("Bn3 Bunny")
  package:set_speed(1)
  package:set_attack(15)
  package:set_health(40)
  package:set_preview_texture_path(_modpath .. "preview.png")
end

-- setup the test package
function package_build(mob)
  local spawner = mob:create_spawner(character_id .. "Bunny", Rank.V1)
  spawner:spawn_at(4, 1)
  local spawner = mob:create_spawner(character_id .. "TuffBunny", Rank.V1)
  spawner:spawn_at(5, 2)
end
