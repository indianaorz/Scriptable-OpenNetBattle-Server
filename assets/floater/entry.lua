local package_id = "flyingfire.co.floater"
local character_id = "flyingfire.co.enemy.floater"

function package_requires_scripts()
  Engine.define_character(character_id, _modpath.."floater")
end

function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("Floater")
  package:set_description("Floating abomination")
  -- package:set_speed(999)
  -- package:set_attack(999)
  -- package:set_health(9999)
  package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
  mob
    :create_spawner(character_id, Rank.V1)
    :spawn_at(5, 2)
end
