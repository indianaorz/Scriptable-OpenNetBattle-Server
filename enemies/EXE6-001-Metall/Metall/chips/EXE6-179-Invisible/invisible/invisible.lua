local print_debug = false

local INVISIBLE_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE6_333.ogg", true)
local SPAWN_AUDIO = Engine.load_audio(_folderpath.."sfx/EXE6_65.ogg", true)

local function debug_print(text)
    if print_debug then
        print("[Invisible] "..text)
    end
end

local invisible = {}

invisible.card_create_action = function(self, props)
    local action = Battle.CardAction.new(self, "PLAYER_IDLE")
    action.execute_func = function(self, user)
        local ReverentFlicker = Battle.Component.new(user, Lifetimes.Battlestep)
        ReverentFlicker.owner = user
        ReverentFlicker.flicker_cooldown = 1
        ReverentFlicker.alpha_index = 1
        ReverentFlicker.end_of_invis = 360
        local ReverentDefense = Battle.DefenseRule.new(20000, DefenseOrder.CollisionOnly)
        ReverentDefense.can_block_func = function(judge, attacker, defender)
            local attacker_props = attacker:copy_hit_props()
            if attacker_props.flags & Hit.Pierce ~= Hit.Pierce then
                judge:block_damage()
            end
            if attacker_props.flags & Hit.Retangible == Hit.Retangible then
                self.owner:reveal()
                defender:remove_defense_rule(ReverentDefense)
                ReverentFlicker:eject()
            end
        end
        ReverentFlicker.update_func = function(self, dt)
            if self.owner:is_deleted() then return end
            if ReverentDefense:is_replaced() then
                self.owner:reveal()
                self.owner:remove_defense_rule(ReverentDefense)
                self:eject()
            end
            if self.end_of_invis <= 0 then
                self.owner:reveal()
                self.owner:remove_defense_rule(ReverentDefense)
                self:eject()
                Engine.play_audio(SPAWN_AUDIO, AudioPriority.Low)
            else
                self.end_of_invis = self.end_of_invis - 1
            end
            if self.flicker_cooldown <= 0 then
                if self.alpha_index == 1 then
                    self.owner:hide()
                else
                    self.owner:reveal()
                end
                self.alpha_index = self.alpha_index + 1
                if self.alpha_index > 2 then self.alpha_index = 1 end
                self.flicker_cooldown = 1
            else
                self.flicker_cooldown = self.flicker_cooldown - 1
            end
        end
        user:register_component(ReverentFlicker)
        user:add_defense_rule(ReverentDefense)
        Engine.play_audio(INVISIBLE_AUDIO, AudioPriority.Low)
    end
    return action
end

return invisible