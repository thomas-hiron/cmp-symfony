local source = {}

local twig_templates = {}

local function load_templates()
  twig_templates = {}

  local handle = io.popen('fd twig templates 2>/dev/null')
  local result = handle:read("*a")
  handle:close()

  for line in result:gmatch("[^\r\n]+") do
    table.insert(twig_templates, {
      label = line:gsub("templates/", ""),
    })
  end

  -- Reload templates in 30 seconds
  vim.defer_fn(load_templates, 30000)
end

load_templates()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'twig_templates'
end

function source.is_available()
  local filetypes = { 'php', 'twig' }

  return next(twig_templates) ~= nil and vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { "'" }
end

function source.complete(self, request, callback)
  local line = vim.fn.getline('.')
  local triggers = { 'render', 'include' }
  local found = false

  -- Trigger only if render or include is present on the line.
  -- This cover most php and twig rendering templates related functions.
  for k, trigger in pairs(triggers) do
    if string.find(line:lower(), trigger) then
      found = true
    end
  end

  if not found then
    callback({isIncomplete = true})

    return
  end

  callback {
    items = twig_templates,
    isIncomplete = true,
  }
end

return source
