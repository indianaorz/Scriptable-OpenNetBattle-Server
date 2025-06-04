local GLOBAL_STATE_FILE = "memory/global_state.lua"

local function encode_table(tbl)
  local lines = {"return {\n"}
  for k, v in pairs(tbl) do
    if type(v) == "string" then
      table.insert(lines, string.format("  [%q] = %q,\n", k, v))
    elseif type(v) == "number" or type(v) == "boolean" then
      table.insert(lines, string.format("  [%q] = %s,\n", k, tostring(v)))
    end
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

local GlobalStateManager = {}

function GlobalStateManager.load_states()
  return Async.promisify(coroutine.create(function()
    local data = Async.await(Async.read_file(GLOBAL_STATE_FILE))
    if data and #data > 0 then
      return decode_table(data)
    else
      return {}
    end
  end))
end

function GlobalStateManager.save_states(tbl)
  local content = encode_table(tbl)
  return Async.write_file(GLOBAL_STATE_FILE, content)
end

return GlobalStateManager
