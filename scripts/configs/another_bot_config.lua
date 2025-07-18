-- scripts/configs/another_bot_config.lua
local config = {
    -- Identity & Appearance
    area_id = "default",
    spawn_object_name = "Bot Spawn 2", -- For the second bot
    bot_name = "GuardBot_Alpha",
    texture_path = "/server/assets/prog.png",
    animation_path = "/server/assets/prog.animation",
    mug_texture_path = "resources/ow/prog/prog_mug.png",
    mug_animation_path = "resources/ow/prog/prog_mug.animation",

    -- Behavior
    speed = 1.5, -- Slightly faster
    bot_collision_size = 0.5,

    -- Dialogue
    dialogue_main_prompt = "State your purpose. I am GuardBot Alpha.",
    dialogue_response_positive = "Understood. Proceed.",
    dialogue_response_negative = "Suspicious. I am watching you.",
    dialogue_busy = "Standby. Attending to another individual.",

    -- Action Sequence
    ACTION_LIST = {
        "move north 4",
        "wait 5.0",
        "move south 4",
        "wait 5.0",
        "loop"
    }
}
return config