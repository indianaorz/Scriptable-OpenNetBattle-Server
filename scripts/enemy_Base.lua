local EnemyBase = {}

function EnemyBase.init(enemy, config)
    enemy._states = config.states or {}
    enemy._current_state = nil
    enemy.frame_counter = 0

    function enemy:set_state(name)
        local state = enemy._states[name]
        if not state then return end
        if enemy._current_state and enemy._current_state.exit then
            enemy._current_state.exit(enemy)
        end
        enemy._current_state = state
        enemy.frame_counter = 0
        if state.enter then state.enter(enemy) end
    end

    enemy.update_func = function(self)
        self.frame_counter = self.frame_counter + 1
        if not self._current_state and config.start_state then
            self:set_state(config.start_state)
        end
        if self._current_state and self._current_state.update then
            self._current_state.update(self, self.frame_counter)
        end
    end
end

return EnemyBase
