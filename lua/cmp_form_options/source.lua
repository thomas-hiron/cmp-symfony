local source = {}
local utils = require('utils')

local filename = 'autocomplete_form_type.json'

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'form_options'
end

function source.is_available()
  local filetypes = { 'php' }

  if not vim.tbl_contains(filetypes, vim.bo.filetype) then
    return false
  end

  local is_form = vim.fn.search('extends AbstractType', 'nc') > 0
  if not is_form then
    return false
  end

  local f = io.open(filename, 'r')

  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function source.get_trigger_characters()
  return { "'" }
end

function source.complete(self, request, callback)
  local text_before_cursor = utils.get_text_before_cursor()

  -- Cursor is after '=>', do not autocomplete
  if text_before_cursor:match('=>') then
    callback({isIncomplete = true})

    return
  end

  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = ts_utils.get_node_at_cursor()

  -- Can't handle treesitter node
  if not node then
    callback({isIncomplete = true})

    return
  end

  -- Find arguments parent, ie the ->add call
  local line
  while node do
    if node:type() == "arguments" then
      -- Get node line + 1 to keep index
      local line_number = node:start() + 1

      line = vim.fn.getline(line_number)

      break
    end

    node = node:parent()
  end

  -- Make sure it is a line for a FormType
  if not line or not line:match('Type::class') then
    callback({isIncomplete = true})

    return
  end

  -- Extract form class name
  local class_name = line:match(', ([A-Za-z0-9]+Type)::class')

  -- Get corresponding form entry
  local handle = io.popen('jq -r ".' .. class_name ..'" ' .. filename .. ' 2>/dev/null')
  local result = handle:read("*a")
  handle:close()

  -- Return if error or FormType not found
  if not result or result:match('null') then
    callback({isIncomplete = true})

    return
  end

  local items = {}
  local json = vim.fn.json_decode(result)

  -- Create autocomplete results
  for option, defined_in in pairs(json) do
    table.insert(items, {
      label = option,
      documentation = {
        kind = 'markdown',
        value = '_Defined in_: ' .. defined_in
      },
    })
  end

  callback {
    items = items,
    isIncomplete = true,
  }
end

return source
