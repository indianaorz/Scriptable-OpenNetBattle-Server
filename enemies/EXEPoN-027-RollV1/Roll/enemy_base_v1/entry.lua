--[[
    This is sort of animator and animation object in one, maybe I want to separate.

    I'll be going through this object to animate myself. I'll call tick every frame in my Entity.update_func
        And maybe when I set state, too, but that call would be in here
    
    I'll have to make a bunch of animation states with big tables and hope I don't use way too much memory
        Not true anymore because that was an awful idea. I was going to make this a sort of map of String state names to 
        animation data, but that doesn't really make much sense to do, does it?
        Well, it would preserve Animation:set_state("State") calls as working without adding extra stuff

]]

local base = {}

--base.anim_states = {}
base.anim_info = nil -- Current animation data, see base.set_state
base.current_state = nil -- String state name, name of index in base.anim_states. Mattered more for dead idea, now it's just so you can query
base.anim_frame = 1
base.anim_time = 0
base.should_loop = false

base.owner = nil -- Entity object who owns this object
base.owner_animation = nil 
base.owner_sprite = nil

base.on_complete_callback = nil
base.on_interrupt_callback = nil

--[[
    Input: Entity owner

    Sets the owner of this object to the input Entity, so it can be used in callbacks and set state calls later.
    Make sure to call this immediately. It's an initialization sort of thing.
]]

base.set_owner = function(self, owner)
    self.owner = owner
    self.owner_animation = owner:get_animation()
    self.owner_sprite = owner:sprite()
end


--[[
    Input: Entity self    

    Increments anim_time
    If anim_time >= the frame's duration (as in the anim_state table), increment the anim_frame and run any necessary callbacks
    On complete default behavior should return to a default state, as defined in base.default_on_complete.
    base.default_on_complete will run only if the state has no on_complete. If you define on_complete, consider calling 
    base.default_on_complete at the end of your on_complete code block if it makes sense to.

    If looping, a set_state to the current state will be done before on_complete is called.
]]
base.tick_animation = function(self)
    -- if something has a 3, it should be visible for 3 ticks
    local cur_frame = self.anim_info[self.anim_frame]
    local time = self.anim_time
 --   print("Tick for "..self.current_state.." frame "..self.anim_frame.." at tick "..time)

    -- Need to play on_frame 1 callback somewhere
    if time == 0 and self.anim_frame == 1 then 
        if cur_frame.on_frame then 
            cur_frame.on_frame()
        end
    end
    
    -- This frame finished
    if time >= cur_frame.duration then 
        -- State completed
        if self.anim_frame == #self.anim_info then 

            -- The on_complete may call a set_state, which could mean we should no longer try to loop this
            -- We can loop first, and then call the on_complete. Waste of time, though
            if self.should_loop then 
                self.set_state(self, self.current_state, self.anim_info, true, true, true)
            end

            if self.on_complete_callback then 
                -- Store in another variable before setting nil
                -- If the on_complete sets a new on_complete, we would overwrite by setting nil after
                local on_complete = self.on_complete_callback
                self.on_complete_callback = nil

                on_complete(self)

               
            else
                self.default_on_complete(self.owner)
            end
        -- Not completed, go to next frame
        else
            self.anim_frame = self.anim_frame + 1
            cur_frame = self.anim_info[self.anim_frame]

            self.owner_animation:set_state(cur_frame.state)
            self.owner_animation:refresh(self.owner_sprite)

            -- Consider treating this as a table later
            if cur_frame.on_frame ~= nil then 
                cur_frame.on_frame()
            end
        end

        time = 0 -- We're visible this frame, so we'll tick to 1
    end

    self.anim_time = time + 1
end

--[[
    Default behavior for animation complete. 
    Think of this as how ONB will return you to idle and set playback to loop.
    It will be called by base.tick_animation if there is no set on_complete callback for the current state.

    This is nothing here, so you should implement it by setting base.default_on_complete to something
]]
base.default_on_complete = function(owner)

end

--[[
    UNUSED BECAUSE BAD, DELETE LATER

    Input: String state_name, Table anim_info

    Make an animation state to be tracked by this object.

    An anim_info object will contain any number of animation data object entries. 
    An anim_info object can also have "on_complete" index, which is a function.
    An animation data object should be a table with an integer "duration" index, a String "state" index

    Example:
    anim_info = {
        {duration = 3, state = "SHOOT1"},
        {duration = 1, state = "SHOOT2", on_frame = do_attack},

    }

    The "state" index in these animation data are recommended to reference an animation state from your Entity's animation file, which is 
    configured to have a single frame. In other words, split your normal animation states into single frames that you can reference here.
    SHOOT1 in the above example would be an animation state containing only the first sprite of the SHOOT animation, and SHOOT2 would be 
    an animation state containing only the second sprite of the SHOOT animation.

    Function callbacks will be called with base.owner as parameter

]]
base.make_state = function(state_name, anim_info)
   -- base = anim_states[state_name] = anim_info
end

--[[
    I should probably just use this, it's a waste of memory to store info on every given animation and its callbacks
    Just do one

    Input: String state_name, Table anim_info, OPTIONAL boolean should_loop, OPTIONAL boolean is_not_Interrupted, OPTIONAL boolean should_keep_complete_callback

    Set a mock animation state to be tracked by this object.

    An anim_info table will contain any number of "animation data" table entries. 
    An animation data table should be a table with an integer "duration" index, a String "state" index, and an optional function "on_frame" index

    Example:
    anim_info = {
        {duration = 3, state = "SHOOT1"},
        {duration = 1, state = "SHOOT2", on_frame = do_attack},

    }

    The "state" index in these animation data are recommended to reference an animation state from your Entity's animation file, which is 
    configured to have a single frame. In other words, split your normal animation states into single frames that you can reference here.
    SHOOT1 in the above example would be an animation state containing only the first sprite of the SHOOT animation, and SHOOT2 would be 
    an animation state containing only the second sprite of the SHOOT animation.

    If should_loop is true, playback is set to Playback.Loop
    If is_not_interrupted is true, we do not play any on_interrupt_callback, else we do
    If should_keep_callback is true, we don't wipe the on_complete callback or the on_interrupt_callback
]]
base.set_state = function(self, state_name, anim_info, should_loop, is_not_interrupted, should_keep_callback)
    -- Things would work the same if I let these stay nil, but just for clarity on what defaults are
    should_loop = should_loop or false
    is_not_interrupted = is_not_interrupted or false
    should_keep_callback = should_keep_callback or false

    self.current_state = state_name
    self.anim_info = anim_info
    self.anim_time = 0
    self.anim_frame = 1

    
    
    self.is_looping = should_loop


    self.owner_animation:set_state(anim_info[1].state)
    self.owner_animation:refresh(self.owner_sprite)

    local interrupt = self.on_interrupt_callback
    self.on_interrupt_callback = nil
    if interrupt then 
        local anim_data = self.anim_info[frame]
    
        -- Only run interrupt if set_state isn't being called from a completed animation
        if not is_not_interrupted then 
            interrupt()
        end
    end

    -- Reset callback if this set_state isn't from our loop call
    -- Probably should've just set anim_time to 0 and anim_frame to 1 in order to loop instead of calling set_state
    if not should_keep_callback then 
        self.on_complete_callback = nil
        self.on_interrupt_callback = interrupt
    end
end

--[[

    Returns String current_state
]]
base.get_state = function(self)
    return self.current_state
end

--[[
    Input: Self, Integer frame, function callback

    Sets a callback to run when the indicated frame is reached
    Will overwrite if there is another callback on the same frame
]]
base.on_frame = function(self, frame, callback)
    local anim_data = self.anim_info[frame]
    if anim_data ~= nil then 
        anim_data.on_frame = callback
    end

end

--[[
    Input: Self, function callback

    Sets a callback to run when the current animation completes
    Will overwrite if there is another callback
]]
base.on_complete = function(self, callback)
    self.on_complete_callback = callback
end


--[[
    Input: Self, function callback

    Sets a callback to run when the current animation is interrupted
    Will overwrite if there is another callback
]]
base.on_interrupt = function(self, callback)
    self.on_interrupt_callback = callback
end


--[[
    Input: Self, Playback playback

    Sets looping if playback is Playback.Loop, else I didn't implement anything else so it's ignored
]]
base.set_playback = function(self, playback)
    if playback == Playback.Loop then 
        self.should_loop = true
    else
        self.should_loop = false
    end
end

base.reset_data = function(self)

end

return base