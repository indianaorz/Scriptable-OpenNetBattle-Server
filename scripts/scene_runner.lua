local BotMovementHelper = require("scripts/bot_movement_helper")

local SceneRunner = {}

function SceneRunner.run(bot_instance, player_id, scene, global_states)
  if not scene then
    return Async.create_promise(function(resolve) resolve() end)
  end

  if bot_instance.player_states[player_id] == nil then
    bot_instance.player_states[player_id] = {}
  end

  return Async.promisify(coroutine.create(function()
    for _, action in ipairs(scene) do
      if action.say then
        Async.await(Async.message_player(player_id, action.say.text,
          bot_instance.bot_object.mug_texture_path,
          bot_instance.bot_object.mug_animation_path))
      elseif action.move then
        Async.await(BotMovementHelper.move_async(bot_instance.bot_object,
          action.move.direction, action.move.distance))
      elseif action.wait then
        Async.await(Async.sleep(action.wait.time or action.wait))
      elseif action.set_state then
        bot_instance.player_states[player_id][action.set_state.key] = action.set_state.value
      elseif action.set_global_state and global_states then
        global_states[action.set_global_state.key] = action.set_global_state.value
      end
    end
  end))
end

return SceneRunner

