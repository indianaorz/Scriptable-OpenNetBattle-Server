local noop = function() end

local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."EXE4_270.ogg")
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."EXE4_221.ogg")

local battle_animation_path = _folderpath.."battle.animation"
local cursor_texture = Engine.load_texture(_folderpath.."cursor.png")
local cursor_animation_path = _folderpath.."cursor.animation"

local BOOM_TEXTURE = Engine.load_texture(_folderpath.."boom.png")
local BOOM_ANIMPATH = _folderpath.."boom.animation"

-- cursor.lua
local Cursor = {}

local function attack_tile(canodumb, attack_spell, tile)
  if not tile then
    attack_spell:erase()
    return
  end

  -- set the cursor up for damage
  attack_spell:set_hit_props(HitProps.new(
    canodumb._attack,
    Hit.Impact | Hit.Flinch | Hit.Flash,
    Element.None,
    canodumb:get_context(),
    Drag.None
  ))

  tile:attack_entities(attack_spell)
end

local function attack(canodumb, cursor)
  Engine.play_audio(canodumb._cannon_sfx, AudioPriority.Low)

  local cursor_anim = cursor.spell:get_animation()
  cursor_anim:set_state("CURSOR_SMOKE")
  cursor_anim:set_playback(Playback.Once)
  cursor_anim:on_complete(function()
    cursor:erase()
  end)

  local canodumb_anim = canodumb:get_animation()
  canodumb_anim:set_state(canodumb._shoot_state)
  canodumb_anim:on_complete(function()
    canodumb_anim:set_state(canodumb._idle_state)
  end)

  -- create a new attack spell to deal damage
  -- we can't deal damage to a target if we've hit them and they haven't moved
  local attack_spell = Battle.Spell.new(canodumb:get_team())

  local tile = canodumb:get_tile()
  local direction = canodumb:get_facing()
  local field = canodumb:get_field()

  attack_spell.update_func = function()
    tile = tile:get_tile(direction, 1)

    attack_tile(canodumb, attack_spell, tile)
  end

  attack_spell.attack_func = function(self, ent)
    -- hit something, dont hit anything more
    create_effect(direction, BOOM_TEXTURE, BOOM_ANIMPATH, "0", math.random(-30,30), math.random(-50,-30), true, -999999, field, ent:get_current_tile())
    if Battle.Obstacle.from(ent) == nil then
      --[[
      if Battle.Player.from(user) ~= nil then
          Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Low)
      end
      ]]
    else
        Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
    end
    attack_spell:erase()
  end

  -- attach the spell so attacks can register
  field:spawn(attack_spell, tile)
end

local function begin_attack(canodumb, cursor)
  -- stop the cursor from scanning for players
  cursor.spell.update_func = noop
  cursor.spell.attack_func = noop

  local cursor_anim = cursor.spell:get_animation()
  cursor_anim:set_state(canodumb._cursor_shoot_state)
  cursor_anim:set_playback(Playback.Once)
  cursor_anim:on_complete(function()
    canodumb._should_attack = true
  end)
end

local function spawn_cursor(cursor, canodumb, tile)
  local spell = Battle.Spell.new(canodumb:get_team())
  spell:set_texture(cursor_texture, true)
  spell:sprite():set_layer(-1)
  spell:set_hit_props(HitProps.new(
    0,
    Hit.None,
    Element.None,
    canodumb:get_context(),
    Drag.None
  ))

  local anim = spell:get_animation()
  anim:load(cursor_animation_path)
  anim:set_state(canodumb._cursor_state)
  anim:set_playback(Playback.Once)

  local field = canodumb:get_field()
  field:spawn(spell, tile)

  spell.update_func = function(action, time)
    cursor.remaining_frames = cursor.remaining_frames - 1

    -- test if we need to move
    if cursor.remaining_frames > 0 then
      return
    end

    tile = tile:get_tile(canodumb:get_facing(), 1)

    if tile then
      cursor.remaining_frames = canodumb._frames_per_cursor_movement + 1
      spell:teleport(tile)
    else
      cursor:erase()
    end
  end

  spell.collision_func = function()
    begin_attack(canodumb, cursor)
  end

  spell.can_move_to_func = function(tile)
    return true
  end

  return spell
end

function Cursor:new(canodumb, tile)
  local cursor = {
    canodumb = canodumb,
    spell = nil,
    remaining_frames = canodumb._frames_per_cursor_movement
  }

  setmetatable(cursor, self)
  self.__index = self

  cursor.spell = spawn_cursor(cursor, canodumb, tile)

  return cursor
end

function Cursor:erase()
  self.spell:erase()
  self.canodumb._cursor = nil
end

-- entry.lua

local target_update, idle_update

target_update = function(canodumb, dt)
  if canodumb._cursor then
    local spell = canodumb._cursor.spell

    spell:get_current_tile():attack_entities(spell)

    if canodumb._should_attack then
        canodumb._should_attack = false
        attack(canodumb, canodumb._cursor)
    end
  else
    canodumb.update_func = idle_update
  end
end

idle_update = function(canodumb, dt)
  local y = canodumb:get_tile():y()
  local team = canodumb:get_team()

  local field = canodumb:get_field()
  local targets = field:find_characters(function(c)
    -- same row, different team
    return c:get_team() ~= team and c:get_tile():y() == y
  end)

  if #targets == 0 then return end -- no target

  -- found a target, spawn a cursor and change state
  local cursor_tile = canodumb:get_tile(canodumb:get_facing(), 1)
  canodumb._cursor = Cursor:new(canodumb, cursor_tile)
  canodumb.update_func = target_update
end

local delete_func = function(canodumb)
  if canodumb._cursor then
    canodumb._cursor:erase()
  end
end

function package_init(self,character_info)
  self._cannon_sfx = Engine.load_audio(_folderpath.."EXE4_241.ogg")

  -- private variables
  self._frames_per_cursor_movement = 15
  self._cursor = nil
  self._idle_state = "0"
  self._shoot_state = "1"
  self._cursor_state = "CURSOR"
  self._cursor_shoot_state = "CURSOR_SHOOT"
  self._attack = character_info.damage
  self._should_attack = false

  self.texture = Engine.load_texture(_folderpath.."battle.greyscaled.png")
  self.animation = self:get_animation()
  self.animation:load(battle_animation_path)

  -- Set up character meta
  self:set_name(character_info.name)
  self:set_health(character_info.hp)
  self:set_texture(self.texture, true)
  self:set_height(character_info.height)
  self:share_tile(false)
  self:set_explosion_behavior(3, 1, false)
  self:set_offset(0, 0)
  self:set_palette(Engine.load_texture(character_info.palette))

  -- setup defense rules
  --self.defense = Battle.DefenseVirusBody.new() -- lua owns this need to keep it alive
  --self:add_defense_rule(self.defense)

  -- setup event hanlders
  self.animation:set_state(self._idle_state)
  self.animation:set_playback(Playback.Once)
  self.update_func = idle_update
  self.battle_start_func = noop
  self.battle_end_func = noop
  self.on_spawn_func = noop
  self.delete_func = delete_func
end

function create_effect(effect_facing, effect_texture, effect_animpath, effect_state, offset_x, offset_y, flip, offset_layer, field, tile)
  local hitfx = Battle.Artifact.new()
  hitfx:set_facing(effect_facing)
  hitfx:set_texture(effect_texture, true)
  hitfx:set_offset(offset_x, offset_y)
  hitfx:never_flip(flip)
  local hitfx_sprite = hitfx:sprite()
  hitfx_sprite:set_layer(offset_layer)
  local hitfx_anim = hitfx:get_animation()
  hitfx_anim:load(effect_animpath)
  hitfx_anim:set_state(effect_state)
  hitfx_anim:refresh(hitfx_sprite)
  hitfx_anim:on_complete(function()
      hitfx:erase()
  end)
  field:spawn(hitfx, tile)

  return hitfx
end

return package_init