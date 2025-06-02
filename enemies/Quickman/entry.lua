--ID of the package
local package_id = "com.louise.Quickman"
-- prefix of the character id
local character_id = "com.louise.enemy."

function package_requires_scripts()
  --Define characters here.
  Engine.define_character(character_id .. "Quickman", _modpath .. "Quickman")
end

--package init.
function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("Quickman")
  package:set_description("Think you can keep up with me?")
  package:set_speed(1)
  package:set_attack(0)
  package:set_health(0)
  package:set_preview_texture_path(_modpath .. "preview.png")
end

-- setup the test package
function package_build(mob)
  local texPath = _modpath .. "BG.png"
  local animPath = _modpath .. "BG.animation"
  mob:set_background(texPath, animPath, -0.1, -0.1)
  local spawner = mob:create_spawner(character_id .. "Quickman", Rank.V3)
  spawner:spawn_at(5, 2)
end
