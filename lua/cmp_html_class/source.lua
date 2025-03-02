local source = {}

local generated_html_classes = vim.fn.expand('~/generated_html_classes.json')

local classes = {}
if vim.fn.filereadable(generated_html_classes) == 1 then
  for k, class in pairs(vim.fn.readfile(generated_html_classes)) do
    local json = vim.fn.json_decode(class)
    table.insert(classes, json)
  end
end

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'html_class'
end

function source.is_available()
  local filetypes = { 'twig', 'html' }

  return next(classes) ~= nil and vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { '"', ' ', }
end

function source.complete(self, request, callback)
  local line = vim.fn.getline('.')

  local triggers = { 'class', }
  local found = false

  -- Trigger only if class is present on the line.
  for k, trigger in pairs(triggers) do
    if string.find(line:lower(), trigger) then
      found = true
    end
  end

  if not found then
    callback({isIncomplete = true})

    return
  end

  local items = {}
  for k, class in pairs(classes) do
    table.insert(items, {
      label = class.class,
      documentation = {
        kind = 'markdown',
        value = '_Found in files_: \n- ' .. table.concat(class.files, '\n- ')
      },
    })
  end

  callback {
    items = items,
    isIncomplete = true,
  }
end

return source
