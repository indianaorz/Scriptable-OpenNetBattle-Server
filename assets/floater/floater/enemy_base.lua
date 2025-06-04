local EnemyBase = {}

function EnemyBase.init(enemy, config)
    enemy._states = config.states or {}
    enemy._current_state = nil
    enemy._state_timer = 0
    enemy._state_data = nil
    enemy._scheduled = {}
    enemy._events = {}
    enemy.frame_counter = 0
    enemy.animation = enemy.animation or enemy:get_animation()
    enemy._last_health = enemy:get_health()

    function enemy:on(event, callback)
        enemy._events[event] = callback
    end

    local function dispatch(event, ...)
        local cb = enemy._events[event]
        if cb then cb(enemy, ...) end
    end

    function enemy:schedule(delay, cb)
        table.insert(enemy._scheduled, {time = enemy.frame_counter + delay, cb = cb})
    end

    function enemy:add_state(name, def)
        enemy._states[name] = def
    end

    function enemy:set_state(name, params)
        local state = enemy._states[name]
        if not state then return end
        if enemy._current_state and enemy._current_state.exit then
            enemy._current_state.exit(enemy, enemy._state_data)
        end
        enemy._current_state = state
        enemy.frame_counter = 0
        enemy._state_timer = state.duration or 0
        enemy._state_data = params or {}

        if state.animation then
            enemy.animation:set_state(state.animation)
            if state.playback then enemy.animation:set_playback(state.playback) end
            enemy.animation:refresh(enemy:sprite())
        end

        if state.enter then state.enter(enemy, enemy._state_data) end
    end

    enemy.update_func = function(self)
        self.frame_counter = self.frame_counter + 1
        local current_health = self:get_health()
        if current_health < self._last_health then
            local damage = self._last_health - current_health
            dispatch("hit", false, damage)
        end
        self._last_health = current_health

        for i = #self._scheduled, 1, -1 do
            local act = self._scheduled[i]
            if self.frame_counter >= act.time then
                act.cb(self)
                table.remove(self._scheduled, i)
            end
        end

        if not self._current_state and config.start_state then
            self:set_state(config.start_state)
        end

        local state = self._current_state
        if state then
            if state.update then state.update(self, self.frame_counter, self._state_data) end

            if self._state_timer > 0 then
                self._state_timer = self._state_timer - 1
                if self._state_timer <= 0 then
                    if state.on_complete then
                        if type(state.on_complete) == "string" then
                            self:set_state(state.on_complete)
                        else
                            state.on_complete(self, self._state_data)
                        end
                    elseif state.next_state then
                        self:set_state(state.next_state)
                    end
                end
            end
        end
    end

    enemy.delete_func = function(self) dispatch("delete") end
    enemy.on_spawn_func = function(self) dispatch("spawn") end
    enemy.battle_start_func = function(self) dispatch("battle_start") end
    enemy.hit_func = function(self, from_stun)
        local current_health = self:get_health()
        local damage = self._last_health - current_health
        self._last_health = current_health
        dispatch("hit", from_stun, damage)
    end

    enemy:register_status_callback(Hit.Flinch, function()
        enemy.hit_func(false)
    end)
    enemy:register_status_callback(Hit.Stun, function()
        enemy.hit_func(true)
        dispatch("stun")
    end)

    if config.on_spawn then enemy:on("spawn", config.on_spawn) end
    if config.on_delete then enemy:on("delete", config.on_delete) end
    if config.on_battle_start then enemy:on("battle_start", config.on_battle_start) end
    if config.on_hit then enemy:on("hit", config.on_hit) end
    if config.on_stun then enemy:on("stun", config.on_stun) end

    if config.start_state then
        enemy:set_state(config.start_state)
    end
end

return EnemyBase
