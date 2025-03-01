local source = {}
local utils = require('utils')

local symfony_routes = {}
local existing_routes = {}

-- Create existing routes from ./var/cache/dev/url_generating_routes.php
local function load_routes()
  local routes = vim.fn.expand('./var/cache/dev/url_generating_routes.php')

  if vim.fn.filereadable(routes) == 1 then
    existing_routes = {}
    symfony_routes = {}

    for k, route in pairs(vim.fn.readfile(routes)) do
      local match = route:match("^ +'([a-z_]+).+")

      if match and not existing_routes[match] then
        table.insert(symfony_routes, match)
        existing_routes[match] = true
      end
    end
  end

  -- Reload routes in 30 seconds
  vim.defer_fn(load_routes, 30000)
end

load_routes()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'symfony_routes'
end

function source.is_available()
  local filetypes = { 'php', 'twig' }

  return next(existing_routes) ~= nil and vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { "'" }
end

function source.complete(self, request, callback)
  local triggers = { 'route', 'path', 'url' }
  local found = false
  local text_before_cursor = utils.get_text_before_cursor()

  -- Trigger only if route, path or url is present on the line.
  -- This cover most php and twig url related functions.
  for k, trigger in pairs(triggers) do
    if string.find(text_before_cursor:lower(), trigger) then
      found = true
    end
  end

  if not found then
    callback({isIncomplete = true})

    return
  end

  local items = {}

  for k, route in pairs(symfony_routes) do
    table.insert(items, {
      label = route,
    })
  end

  callback {
    items = items,
    isIncomplete = true,
  }
end

return source
