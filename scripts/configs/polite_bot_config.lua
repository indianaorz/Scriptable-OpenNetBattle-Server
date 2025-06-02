-- scripts/configs/polite_bot_config.lua
local config = {
    -- Identity & Appearance
    area_id = "default",
    spawn_object_name = "Bot Spawn", -- For the first bot
    bot_name = "PoliteActionBot_1",
    texture_path = "/server/assets/prog.png",
    animation_path = "/server/assets/prog.animation",
    mug_texture_path = "resources/ow/prog/prog_mug.png",
    mug_animation_path = "resources/ow/prog/prog_mug.animation",
    
    -- Behavior
    speed = 1,
    bot_collision_size = 0.5,
    
    -- Dialogue
    dialogue_main_prompt = "Greetings! I am the first Polite Bot. How can I help you on my patrol?",
    dialogue_response_positive = "Excellent!",
    dialogue_response_negative = "Ah, I see.",
    dialogue_busy = "One moment please, I'm assisting someone else.",

    -- Action Sequence
    ACTION_LIST = {
    "move south 2",
    "wait 2.0",
    "move east 2",
    "move north 1",
    "move east 1",
    "wait 1.5",
    "move north 2",
    "move west 3",
    "move south 1",
    "loop"
}
}
return config