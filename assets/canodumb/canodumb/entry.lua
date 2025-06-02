-- jumping_enemy.lua
-- Defines an enemy that jumps to a random tile on its side every second,
-- structured similarly to the provided example and using Canodumb assets.

-- A no-operation function, useful for default event handlers.
local noop = function () end

-- Asset paths (assuming _folderpath is provided by the game engine and points to the mod's asset directory)
-- These will be loaded in package_init.
local CANODUMB_TEXTURE_PATH = _folderpath .. "floater.png"
local CANODUMB_ANIMATION_PATH = _folderpath .. "floater.animation"
local JUMP_SFX_PATH = _folderpath .. "cannon.ogg" -- Using Canodumb's cannon sound for jump
local battle_helpers = include("battle_helpers.lua")

local TELEPORT_TEXTURE = Engine.load_texture(_folderpath .. "teleport.png")
local TELEPORT_ANIM = _folderpath .. "teleport.animation"


-- Shadow-specific assets
local SHADOW_TEXTURE  = Engine.load_texture(_folderpath .. "shadow.png")
local SHADOW_ANIMPATH = _folderpath .. "shadow.animation"   -- a simple 1‑frame loop

-- Loaded assets (will be populated in package_init if not already loaded globally or per instance)
local g_canodumb_texture = nil
local g_jump_sfx = nil
-- Note: Animation path is usually loaded per instance via anim:load(path)

--- Main update function for the JumpingEnemy.
--- Called every frame by the game engine.
---@param self Entity The enemy instance.
---@param dt number Delta time (not explicitly used here as logic is frame-based).
local function jumping_enemy_update(self, dt)
    self.frame_counter = self.frame_counter + 1

    if self.frame_counter >= self.jump_interval_frames then
        self.frame_counter = 0 -- Reset counter

        -- Play jump sound effect
        if g_jump_sfx then
            Engine.play_audio(g_jump_sfx, AudioPriority.Low)
        end

        battle_helpers.spawn_visual_artifact(self:get_field(), self:get_tile(), TELEPORT_TEXTURE, TELEPORT_ANIM,
                "MEDIUM_TELEPORT_FROM",
                0, 0)

        -- Move the enemy immediately
        battle_helpers.move_random_adjacent(self)
            
        -- Ensure animation returns to/stays in idle state
        local anim = self.animation -- Access stored animation controller
        if anim:get_current_state_name() ~= self.idle_anim_state or anim:get_playback() ~= Playback.Loop then
            anim:set_state(self.idle_anim_state)
            anim:set_playback(Playback.Loop)
            anim:on_complete(nil) -- Clear any previous on_complete callback
        end
    end
end

--- Initializes the JumpingEnemy instance.
---@param self Entity The enemy instance.
---@param character_info table Optional table with character data (not used in this version).
function package_init(self, character_info)
    -- Load assets once
    if not g_canodumb_texture then
        g_canodumb_texture = Engine.load_texture(CANODUMB_TEXTURE_PATH)
    end
    if not g_jump_sfx then
        g_jump_sfx = Engine.load_audio(JUMP_SFX_PATH)
    end

    -- Common Properties
    self:set_name("JumpingEnemy")
    self:set_health(50) -- Example health
    self:set_height(64) -- Using Canodumb's height
    self:set_element(Element.None) -- Or specify an element

    -- Texture and Animation
    if g_canodumb_texture then
        self:set_texture(g_canodumb_texture)
    end
    self.animation = self:get_animation() -- Get the animation controller attached to this entity
    self.animation:load(CANODUMB_ANIMATION_PATH) -- Load Canodumb's animations

    -- JumpingEnemy Specific Properties
    self.jump_interval_frames = 20 -- Approx 1 second at 60 FPS
    self.frame_counter = 0
    self.idle_anim_state = "Idle"       -- From Canodumb
    self.move_speed = 10
    self.recovery_speed = 0
    -- self.action_anim_state = "SHOOT_1" -- Removed: No specific action animation for jump to avoid "shoot" appearance

    -- Set initial animation state
    self.animation:set_state(self.idle_anim_state)
    self.animation:set_playback(Playback.Loop)

    -- Defense
    self.defense = Battle.DefenseVirusBody.new()
    self:add_defense_rule(self.defense)

    -- Assign event handlers
    self.update_func = jumping_enemy_update
    
    self.battle_start_func = function(enemy_instance)
        enemy_instance.frame_counter = 0 -- Reset on battle start
    end

    self.on_spawn_func = function(enemy_instance)
        -- Randomize initial timer slightly to desynchronize multiple instances
        enemy_instance.frame_counter = math.random(0, enemy_instance.jump_interval_frames -1)
        -- Ensure animation is correctly set on spawn
        if enemy_instance.animation:get_current_state_name() ~= enemy_instance.idle_anim_state then
            enemy_instance.animation:set_state(enemy_instance.idle_anim_state)
            enemy_instance.animation:set_playback(Playback.Loop)
        end
    end
    
    self.battle_end_func = noop

     --------------------------------------------------------------------------
    -- 2)  Create a child node that will act as the shadow
    --------------------------------------------------------------------------
    local shadow_node  = self:create_node()          -- child of the virus
    shadow_node:set_texture(SHADOW_TEXTURE, true)
    -- Separate Anim object because nodes don’t come with one.
    local shadow_anim  = Engine.Animation.new(SHADOW_ANIMPATH)
    shadow_anim:set_state("default")
    shadow_anim:set_playback(Playback.Loop)
    shadow_anim:refresh(shadow_node)
    
    local shadow_component          = Battle.Component.new(self, Lifetimes.Battlestep)
    -- shadow_node:set_offset(0, 0)   -- or whatever puts it on the ground
    

    self:register_component(shadow_component)

    -- keep a reference so we can access it later
    self._shadow_node = shadow_node

    self.delete_func = function(enemy)
        if enemy._shadow_node then
            -- ① easiest: just stop drawing it
            enemy._shadow_node:hide()
            -- ② or, cleanly remove it from the node tree
            enemy:remove_node(enemy._shadow_node)
            enemy._shadow_node = nil
        end
    end


    -- Log.info("JumpingEnemy (new structure) initialized: " .. self:get_name())
end

return package_init
