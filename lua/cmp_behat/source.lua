local source = {}

local steps = {}

local function load_behat()
  local handle = io.popen('rg "\\* @(Given|When|Then)" vendor behat --no-messages --vimgrep')
  local result = handle:read("*a")
  handle:close()

  steps = {}
  for line in result:gmatch("[^\r\n]+") do
    local file_name = line:gsub(":.+", "")
    local step_full = line:gsub("^.+@[A-Za-z]+ ", "")

    -- Remove variables
    local step = step_full:gsub(" :[A-Za-z]+", " \"\"")

    -- Remove start and end
    step = step:gsub("/^", "")
    step = step:gsub("%$?/$", "")

    -- Replace (?:|I ) block
    step = step:gsub("%(I %)", "I ")
    step = step:gsub("%([^%)]+I %)", "I ")
    step = step:gsub("%([^%)]+the %)", "the ")

    -- Remove "(?P<button>(?:[^"]|\\")*)"
    step = step:gsub("\"?%(%?P<[^ ]+%)\"?", "\"\"")

    -- Remove an? or elements?
    step = step:gsub("[ns]%?", "")

    table.insert(steps, {
      label = step,
      documentation = {
        kind = 'markdown',
        value = '_File_: ' .. file_name .. '\n' .. '_Definition_: ' .. step_full
      },
    })
  end

  -- Reload in 60 seconds
  vim.defer_fn(load_behat, 60000)
end

load_behat()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'behat'
end

function source.is_available()
  local filetypes = { 'cucumber' }

  return vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { 'd', 'n' }
end

function source.complete(self, request, callback)
  callback {
    items = steps,
    isIncomplete = true,
  }
end

return source
