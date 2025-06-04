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

## Proposed Data‑Driven State Machine

Many enemies re‑implement similar state and animation logic in Lua. To avoid duplication a simple state machine definition can be expressed as data. Below is a conceptual proposal for such a configuration.

```lua
local enemy_cfg = {
  name = "Example",
  hp = 100,
  states = {
    idle = {
      animation = "IDLE",
      transitions = {
        { on = "attack", to = "attack" },
        { on = "hit",    to = "flinch" }
      }
    },
    attack = {
      animation = "ATTACK",
      on_enter = function(self) do_attack(self) end,
      on_complete = "idle"
    },
    flinch = {
      animation = "FLINCH",
      duration = 20,
      on_complete = "idle"
    }
  }
}
```

A generic helper could read this table and create the corresponding callbacks on the character object. New enemies would only need to provide animation names and optionally small snippets such as `do_attack`. This removes large blocks of boiler‑plate for setting animation states and managing transitions.

A loader in `package_requires_scripts` could parse a JSON or Lua file describing the states and generate the runtime behaviour automatically. Existing enemies could gradually migrate to this approach to share common patterns like idle‑attack‑flinch loops without rewriting the logic each time.

