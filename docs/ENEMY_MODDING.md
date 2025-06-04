# Creating New Enemies and Encounters

This document outlines the workflow for adding new enemy packages and how to set up their encounters in the server. It also proposes a more data‑driven approach for enemy state machines so that new enemies can reuse behaviour definitions.

## Enemy Package Layout

Enemy content lives under the `enemies/` directory. Each enemy package is a folder (or a zip archive) containing a top level `entry.lua` and a subfolder with the character implementation.

```
enemies/
  MyEnemy/
    entry.lua            -- package registration
    MyEnemy/
      entry.lua          -- character behaviour
      *.png / *.ogg      -- art and audio assets
      *.animation        -- animation files
```

The root `entry.lua` registers the package with the engine. A minimal example is the *Floater* enemy:

```lua
local package_id = "flyingfire.co.floater"
local character_id = "flyingfire.co.enemy.floater"

function package_requires_scripts()
  Engine.define_character(character_id, _modpath.."floater")
end

function package_init(package)
  package:declare_package_id(package_id)
  package:set_name("Floater")
  package:set_description("Floating abomination")
  package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob)
  mob:create_spawner(character_id, Rank.V1)
     :spawn_at(5, 2)
end
```

`package_build` is responsible for creating a `Spawner` which will create the enemy character during the encounter. The character folder contains another `entry.lua` implementing the behaviour of the enemy using the scripting API.

After the folder is prepared it can be zipped (the zip file can also be placed in `enemies/`):

```bash
zip -r MyEnemy.zip MyEnemy
```

## Creating New Encounters

Encounters define which enemies appear when a player moves around an area. The helper library `scripts/libs/encounters.lua` provides an easy way to configure them. Take a look at `scripts/example_encounters.lua` for a sample setup. An encounter table looks like this:

```lua
local Encounters = require("scripts/libs/encounters")
local table = {
  ["default"] = {
    min_travel = 2,      -- tiles the player can move before checks begin
    chance = 0.05,       -- probability per movement to trigger an encounter
    preload = true,      -- optional: pre‑load assets
    encounters = {
      { asset_path = "/server/assets/floater.zip", weight = 0.1 },
    }
  }
}
Encounters.setup(table)
```

`weight` is relative. All weights in an area are normalised to 1.0. Once configured you can call `Encounters.track_player(player_id)` when a player joins and `Encounters.handle_player_move(player_id, x, y, z)` whenever the player moves. The helpers take care of selecting and spawning the enemy package.

### Using `enemy_base.lua`

The Floater enemy ships with a small reusable helper at
`assets/floater/floater/enemy_base.lua`. It implements a lightweight
state machine and several common hooks so other enemies do not need to
repeat boiler‑plate code.

Features include:

- Named states with optional `enter`, `update` and `exit` callbacks.
- Automatic timers via a `duration` field and `next_state`/`on_complete`
  transitions.
- Event hooks for `spawn`, `battle_start`, `hit`, `stun` and `delete`.
- A scheduler available through `enemy:schedule(frames, callback)`.
- Basic animation management when a state specifies `animation` and
  `playback`.

Load the helper with `include("enemy_base.lua")` and initialise it:

```lua
enemy_base.init(self, {
  states = states,
  start_state = "IDLE",
  on_delete = function(e)
    -- cleanup logic
  end
  ,on_hit = function(e, from_stun)
    -- react to damage
  end
})
```

States can then be described purely in data while custom behaviour is
added through the callbacks.


#### Event hooks

Callbacks registered with `enemy:on(name, cb)` are stored per enemy instance and automatically tied to the engine's lifecycle hooks. The helper replaces the built-in `update_func`, `delete_func`, `on_spawn_func`, `battle_start_func` and `hit_func` so events fire whenever those functions run. Hooks are not tied to states, but to the creature as a whole. You can therefore listen for `hit` or `stun` even while in any state.

```
self:on("spawn", function(e)
  -- executed once the enemy is placed on the field
end)
self:on("delete", function(e)
  -- cleanup when removed
end)
```

#### Spawning projectiles

Projectiles are usually implemented as `Battle.Spell` objects. Create the spell, configure its hit properties and behaviour, then spawn it on the field:

```lua
local spell = Battle.Spell.new(self:get_team())
spell:set_hit_props(HitProps.new(40, Hit.Impact | Hit.Flinch, Element.None,
                                self:get_context(), Drag.None))
spell.update_func = function(s)
  s:get_current_tile():attack_entities(s)
  local dest = s:get_tile(self:get_facing(), 1)
  s:slide(dest, frames(4), frames(0), ActionOrder.Voluntary)
end
self:get_field():spawn(spell, self:get_tile(self:get_facing(), 1))
```

#### Creating obstacles

Obstacles work similarly using `Battle.Obstacle.new`. They persist on the field until deleted. An obstacle can notify the enemy when it is destroyed via its `delete_func`:

```lua
local rock = Battle.Obstacle.new(self:get_team())
rock:set_health(40)
rock.delete_func = function(o)
  -- obstacle disappeared, switch behaviour
  self:set_state("IDLE")
end
self:get_field():spawn(rock, target_tile)
```

The enemy can also keep a reference to the spawned obstacle if it needs to check its state in later updates.
