local source = {}

local native_filters = require('cmp_twig.filters')
local native_functions = require('cmp_twig.functions')
local filters = {}
local functions = {}

local function load_twig()
  local handle = io.popen('rg --no-filename --no-line-number --no-heading --no-messages "new Twig(Filter|Function)" src')
  local result = handle:read("*a")
  handle:close()

  filters = {}
  functions = {}

  for line in result:gmatch("[^\r\n]+") do
    local is_filter = line:match("TwigFilter") ~= nil
    local match = line:match("new Twig[A-Za-z]+%('([A-Za-z0-9_]+)'")

    if is_filter then
      table.insert(filters, match)
    else
      table.insert(functions, match)
    end
  end

  -- Reload in 30 seconds
  vim.defer_fn(load_twig, 30000)
end

load_twig()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'twig'
end

function source.is_available()
  local filetypes = { 'twig' }

  return vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { '|', ' ', '(' }
end

function source.complete(self, request, callback)
  local input = string.sub(request.context.cursor_before_line, request.offset - 1)

  local completion_array
  local native_completion_array
  local documentation

  if vim.startswith(input, '|') then
    completion_array = filters
    native_completion_array = native_filters
    documentation = "Filter"
  else
    completion_array = functions
    native_completion_array = native_functions
    documentation = "Function"
  end

  local items = {}
  for k, completion in pairs(completion_array) do
    table.insert(items, {
      label = completion,
      documentation = {
        kind = 'markdown',
        value = '_Twig type_: ' .. documentation
      },
    })
  end

  for k, completion in pairs(native_completion_array) do
    table.insert(items, {
      label = completion,
      documentation = {
        kind = 'markdown',
        value = '_Twig type (native)_: ' .. documentation
      },
    })
  end

  callback {
    items = items,
    isIncomplete = true,
  }
end

return source
