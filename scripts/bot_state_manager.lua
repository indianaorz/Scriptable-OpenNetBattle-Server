local BOT_STATE_FOLDER = "memory/player_bot_states/"

local function url_encode(str)
  return (str:gsub("[^%w%-_.]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function encode_table(tbl)
  local lines = {"return {\n"}
  for bot, state in pairs(tbl) do
    table.insert(lines, string.format("  [%q] = {\n", bot))
    for k, v in pairs(state) do
      if type(v) == "string" then
        table.insert(lines, string.format("    %s = %q,\n", k, v))
      elseif type(v) == "number" or type(v) == "boolean" then
        table.insert(lines, string.format("    %s = %s,\n", k, tostring(v)))
      end
    end
    table.insert(lines, "  },\n")
  end
  table.insert(lines, "}\n")
  return table.concat(lines)
end

local function decode_table(str)
  local chunk = load(str)
  if not chunk then return {} end
  local ok, tbl = pcall(chunk)
  if ok and type(tbl) == "table" then
    return tbl
  end
  return {}
end

local BotStateManager = {}

function BotStateManager.load_states(player_id)
  local identity = Net.get_player_secret(player_id)
  local path = BOT_STATE_FOLDER .. url_encode(identity) .. ".lua"
  return Async.promisify(coroutine.create(function()
    local data = Async.await(Async.read_file(path))
    if data and #data > 0 then
      return decode_table(data)
    else
      return {}
    end
  end))
end

function BotStateManager.save_states(player_id, tbl)
  local identity = Net.get_player_secret(player_id)
  local path = BOT_STATE_FOLDER .. url_encode(identity) .. ".lua"
  local content = encode_table(tbl)
  return Async.write_file(path, content)
end

return BotStateManager
