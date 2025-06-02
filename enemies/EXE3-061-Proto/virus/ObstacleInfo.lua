--[[
    ObstacleInfo, by Alrysc
    v1.1

    
    Initial version: Aug. 17, 2023

    v1.1: April 28, 2025
        - Changed the flag values, which fixes an issue where using 
            both flags at the same time would have incorrect behavior, 
            and an issue where it could falsely flag.


    File to be included to handle the following ideas:

    1. In ONB, Obstacles are the catch-all for non-Characters that have hurtboxes.
    BN uses Obstacles in ways that require more sophisticated tagging to replicate.

    2. BN has non-Characters that have hurtboxes that can also not be hit by chips
    that specifically target Obstacles, such as Lightning. This file solves this 
    with the set_cannot_be_targeted function. 

    3. BN has Obstacles that have hurtboxes, and that can be targeted by effects 
    like Lightning, but cannot be directly manipulated by effects like Poltergeist 
    and DustCross. This file solves this with the set_cannot_be_manipulated function.

    4. BN has Obstacle limits. Some chips fit into a category that allows only 1, or 
    only 2 at a time, and these limits apply for a particular team (NOT necessarily 
    the Obstacle's team). This file solves this with the add_to_limit_1, add_to_limit_2, 
    and the broader set_obstacle_priority functions.


    Example use cases:

    FlashBomb has a hurtbox and HP (is an Obstacle) but cannot be hit by lightning or eaten
    by Dust. I'll make sure I call ObstacleInfo.set_cannot_be_targeted(FlashBomb, true) and 
    ObstacleInfo.set_cannot_be_manipulated(FlashBomb, true).

    Alpha's arms have hurtboxes (are Obstacles) and can be hit by Lightning, but not Poltergeist.
    I'll make sure to call ObstacleInfo.set_cannot_be_manipulated(AlphaArm, true).

    I want to make my sword attack reflect things. I do this by spawning a hurtbox that can detect 
    and block an attack ahead, so it's an Obstacle by code. But, logically speaking, it's not an 
    object on the field that we see, so I make sure to call ObstacleInfo.set_cannot_be_targeted(ReflectBox, true) 
    and ObstacleInfo.set_cannot_be_manipulated(ReflectBox, true).



    If you're only here for checking how to use the functions this gives, skip
    past the local variables and functions. They're local to this file, so you 
    can only reference the indexes on ObstacleInfo for your return object
    (ObstacleInfo.something = function())

    Comments in here will be written with the assumption that you have a line 
    like

        local ObstacleInfo = include("ObstacleInfo/entry.lua")

    
    Some important details about current implementation that you may want to note:

    1. Tagging is done by changing the Obstacle's HitProps. So I ask you to kindly not 
    touch those. This usually shouldn't cause any issue, because you have almost no 
    reason to use an Obstacle's HitProps. If you were using them for collision damage 
    or something before this, please use a new variable instead of the Obstacle's index.

    2. Obstacle limits are assumed to be added *before* you spawn your Obstacle, since I 
    can't query if you're spawned yet. For certain effects, like how RockCube sort of half 
    spawns when it isn't allowed to spawn on the tile, just use an Artifact or Spell or 
    something instead if it fails to spawn, and add it to the limit before trying that 
    for the actual BN behavior. 

    3. Tagging is phrased as opt-out. So all your old Obstacles, by default, are:
        - Infinite limit
        - Able to be targeted by Lightning, etc.
        - Able to be manipulated by Dust sucking you up, or by bring thrown by Poltergeist, etc.
    If you want to change that, check out the functions here.
    
    However, chips or other things that do these effects need to opt-in to watching these 
    cases. They'll need to not suck you up if you set_cannot_manipulate, for example. Those 
    chips will also include this file and use teh functions here. Ask those mod uploaders to 
    check this file out.


]]


local ObstacleInfo = {}

--[[
    Opt- **OUT** tagging. 
    
    If you don't want to be hit by Lightning or Repair, add Cannot_Be.Targeted
    If you don't want to be hit by Poltergeist or sucked up by Dust, add Cannot_Be.Manipulated

]] 
local Cannot_Be = {
    -- Effects that search for obstacles return obstacles with this tag, e.g. Lightning does not consider it an obstacle to strike
    Targeted = 1, 
    -- For effects that directly manipulate an obstacle, e.g. cannot be lifted by Poltergeist, sucked by Dust
    Manipulated = 2, 
}

local function add_flag(obstacle, flag)
    local props = obstacle:copy_hit_props()
    props.flags = props.flags | flag
    obstacle:set_hit_props(props)
end

local function remove_flag(obstacle, flag)
    local props = obstacle:copy_hit_props()
    props.flags = props.flags & ~flag
    obstacle:set_hit_props(props)
end

local function has_flag(obstacle, flag)
    local props = obstacle:copy_hit_props()
    return (props.flags | flag) == props.flags
end

--[[
    Returns list of all Obstacles matching given team and priority

    Priority is treated as the 'damage' field of the Obstacle's HitProps
    Team is treated as the 'element' field of the Obstacle's HitProps

    Input:
        field to search
        team of priority
        Integer priority to check

]]
local function find_obstacles_at_priority(field, team, priority)
    return (field:find_obstacles(function(ob)
        local p = ob:copy_hit_props()
        return p.element == team and p.damage == priority
    end))
end

--[[
    Returns Entity in list with smallest ID. 
    In other words, the oldest Entity

    Input:
        list to check

]]
local function get_oldest(list)
    local oldest = list[1]:get_id()
    local index = 1
    for i=2, #list
    do
        if list[i]:get_id() < oldest then 
            oldest = list[i]:get_id()
            index = i
        end
    end

    return list[index]
end

--[[
    Check Obstacles on same priority 
    If more are found than the priority allows, delete oldest

    Input:
        field to check
        team to add Obstacle to 
        Integer priority to check limits of 

    Note that priority 0 is treated as infinite limit, and is not checked
    Priority 2 is two Obstacle limit
    Any other is a limit of 1. We delete older Obstacles on the same priority


    ASSUMPTION: I assume that this is called before the Obstacle is spawned. Therefore, obstacle 
    limit 1 is exceeded when this is called while there is at least 1 Obstacle on the 
    field on this priority. Limit 2 is exceeded when there are at least 2 on the field.

    The reason for this is that RockCube going over Obstacle limit in BN6 destroys older 
    Obstacles even if the RockCube fails to spawn.

]]
local function check_limits(field, team, priority)
    if priority == 0 then return end
    
    local obstacles_with_priority = find_obstacles_at_priority(field, team, priority)
    if priority ~= 2 then 
        if #obstacles_with_priority > 0 then    
            local old = get_oldest(obstacles_with_priority)
            old:set_health(0)
            old:delete()
        end
    else
        if #obstacles_with_priority > 1 then    
            local old = get_oldest(obstacles_with_priority)
            old:set_health(0)
            old:delete()
        end
    end
end

--[[
    Toggles tagging for if obstacle can be targeted as if they were obstacles

    Input:
        obstacle to apply to
        bool should_add
            'true' - add flag, cannot be targeted
            'false' - remove flag, can be targeted again

    Note that default behavior, without calling this function, allows targeting

    Call with 'true' if you don't want your obstacle to get hit by Lightning, Repair
    Usually if you want this, you also want set_cannot_be_manipulated

    FlashBomb would want both true.


    Example:


    local flashbomb = Battle.Obstacle.new(Team)
    ObstacleInfo.set_cannot_be_targeted(flashbomb, true)
    ObstacleInfo.set_cannot_be_manipulated(flashbomb, true)

]]
ObstacleInfo.set_cannot_be_targeted = function(obstacle, should_add)
    if should_add then 
        add_flag(obstacle, Cannot_Be.Targeted)
    else
        remove_flag(obstacle, Cannot_Be.Targeted)
    end
end

--[[
    Toggles tagging for if obstacle can be manipulated by certain chip effects

    Input:
        obstacle to apply to
        bool should_add
            'true' - add flag, cannot be manipulated
            'false' - remove flag, can be manipulated again

    Note that default behavior, without calling this function, allows targeting

    Call with 'true' if you don't want your obstacle to get picked up by Poltergeist or sucked up by Dust
    Usually if you want this, you also want set_cannot_be_manipulated

    Alpha arms would want this to be true.


    Example:


    local alpha_arm = Battle.Obstacle.new(Team)
    ObstacleInfo.set_cannot_be_targeted(alpha_arm, true)
    ObstacleInfo.set_cannot_be_manipulated(alpha_arm, true)

]]
ObstacleInfo.set_cannot_be_manipulated = function(obstacle, should_add)
    if should_add then 
        add_flag(obstacle, Cannot_Be.Manipulated)
    else
        remove_flag(obstacle, Cannot_Be.Manipulated)
    end
end

--[[
    Query if given obstacle can be targeted as if they were obstacles

    Input:
        obstacle to query tags on 
       

    Effects like Lightning or Repair, which target Obstacles specifically, 
    want to check this for valid targets

    In other words, returning false on this means the Obstacle wants you to 
    act as if this isn't an Obstacle, for the purposes of effects that target 
    Obstacles only

    Note that this sounds an awful lot like Poltergeist wants to check it, too, 
    but since there's another tag for that, Poltergeist will probably only 
    check that, instead of also checking if the Obstacle is targetable. 


    Example:


    local list_of_obstacles_to_hit_with_lightning = field:find_obstacles(function(ob)
        return ObstacleInfo.can_be_targeted(ob)
    end)

]]
ObstacleInfo.can_be_targeted = function(obstacle)
    return not has_flag(obstacle, Cannot_Be.Targeted)
end

--[[
    Query if given obstacle can be manipulated by things that want to drastically 
    affect Obstacles, e.g. Poltergeist

    Input:
        obstacle to query tags on 
       

    Effects like Poltergeist or Dust suck, which affect Obstacles in certain ways, 
    want to check this for valid targets


    Example:


    local list_of_obstacles_to_throw_with_poltergeist = field:find_obstacles(function(ob)
        return ObstacleInfo.can_be_manipulated(ob)
    end)

]]
ObstacleInfo.can_be_manipulated = function(obstacle)
    return not has_flag(obstacle, Cannot_Be.Manipulated)
end

--[[
    Sets an Obstacle to be priority 1 for given team

    Input:
        obstacle to set priority on
        team of Obstacle's priority 


    ASSUMPTION: I assume that this is called before the Obstacle is spawned. Therefore, obstacle 
    limit 1 is exceeded when this is called while there is at least 1 Obstacle on the 
    field on this priority. Limit 2 is exceeded when there are at least 2 on the field.

    The reason for this is that RockCube going over Obstacle limit in BN6 destroys older 
    Obstacles even if the RockCube fails to spawn.

]]
ObstacleInfo.add_to_limit_1 = function(obstacle, team, field)
    ObstacleInfo.set_obstacle_priority(obstacle, team, 1, field)
end

--[[
    Sets an Obstacle to be priority 1 for given team

    Input:
        obstacle to set priority on
        team of Obstacle's priority 


    ASSUMPTION: I assume that this is called before the Obstacle is spawned. Therefore, obstacle 
    limit 1 is exceeded when this is called while there is at least 1 Obstacle on the 
    field on this priority. Limit 2 is exceeded when there are at least 2 on the field.

    The reason for this is that RockCube going over Obstacle limit in BN6 destroys older 
    Obstacles even if the RockCube fails to spawn.

]]
ObstacleInfo.add_to_limit_2 = function(obstacle, team, field)
    ObstacleInfo.set_obstacle_priority(obstacle, team, 2, field)
end

--[[
    Sets an Obstacle to be a certain priority for given team
    Then, checks if existing Obstacles on field surpass priority's limit
    Older Obstacles are deleted, if so

    Input:
        obstacle to set priority on
        team of Obstacle's priority 
        Integer priority to add to

    Note that priority 0 is treated as infinite limit, and is not checked
    Priority 2 is two Obstacle limit
    Any other is a limit of 1. We delete older Obstacles on the same priority

    Priority is treated as the 'damage' field of the Obstacle's HitProps
    Team is treated as the 'element' field of the Obstacle's HitProps
    

    ASSUMPTION: I assume that this is called before the Obstacle is spawned. Therefore, obstacle 
    limit 1 is exceeded when this is called while there is at least 1 Obstacle on the 
    field on this priority. Limit 2 is exceeded when there are at least 2 on the field.

    The reason for this is that RockCube going over Obstacle limit in BN6 destroys older 
    Obstacles even if the RockCube fails to spawn.

]]
ObstacleInfo.set_obstacle_priority = function(obstacle, team, priority, field)
    local props = obstacle:copy_hit_props()
    props.damage = priority
    props.element = team
    obstacle:set_hit_props(props)

    check_limits(field, team, priority)
end

return ObstacleInfo