local source = {}

local symfony_translations = {}

-- Create existing translations from ./var/cache/dev/translations/catalog.fr
local function load_translations()
  local handle = io.popen('find ./var/cache/dev/translations -name "catalogue.fr.*.php" 2>/dev/null')
  local result = handle:read("*a")
  handle:close()

  local translations = vim.fn.expand(result:gsub("%s+", ""))

  if vim.fn.filereadable(translations) == 1 then
    symfony_translations = {}

    local translation_domain, key, value;
    for k, translation in pairs(vim.fn.readfile(translations)) do
      -- translation domain as array key
      if translation:match("'[^']+' => *$") then
        translation_domain = translation:match("'([^']+)'")
        symfony_translations[translation_domain] = {}

      -- translation key and its value (can be one or multi line, hence the gsub)
      elseif translation:match("'[^']+' => '") then
        key, value = translation:match("'([^']+)' => '(.+)")
        symfony_translations[translation_domain][key] = value:gsub("',$", "")

      -- end of multi line or array
      elseif translation == "'," or translation:match(" +%),") then
        key = nil

      -- concat multi lines
      elseif key and translation and symfony_translations[translation_domain][key] then
        symfony_translations[translation_domain][key] = symfony_translations[translation_domain][key] .. "\n" .. translation
      end
    end
  end

  -- Reload translations in 60 seconds
  vim.defer_fn(load_translations, 60000)
end

load_translations()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'symfony_translations'
end

function source.is_available()
  local filetypes = { 'php', 'twig' }

  return next(symfony_translations) ~= nil and vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { "'" }
end

function source.complete(self, request, callback)
  local line = vim.fn.getline('.')
  local triggers = { 'trans', 'addflash', 'message: ', "'label' =>", "'choice_label' =>" }
  local found = false
  local isFlash = false
  local isValidator = false

  -- Trigger only if trans, addflash or :message (for assert attributes) is present on the line.
  -- This cover most php and twig url related functions.
  for k, trigger in pairs(triggers) do
    if string.find(line:lower(), trigger) then
      found = true
    end

    -- if flash or validators, this is used to filter completion results by translation domain
    if string.find(line:lower(), "addflash") then
      isFlash = true
    elseif string.find(line:lower(), "message: ") then
      isValidator = true
    end
  end

  if not found then
    callback({isIncomplete = true})

    return
  end

  local items = {}
  for translation_domain, translations in pairs(symfony_translations) do
    if isFlash and translation_domain ~= "flashes_messages" then
      goto continue
    end

    if isValidator and translation_domain ~= "validators" then
      goto continue
    end

    -- autocomplete translation domains
    table.insert(items, {
      label = translation_domain,
      labelDetails = {
        detail = "domain"
      },
    })

    for key, value in pairs(translations) do
      -- truncate keys to 50 chars
      local label = #key > 50 and string.sub(key, 1, 50).."..." or key

      table.insert(items, {
        label = label .. " (" .. translation_domain .. ")",
        insertText = key,
        documentation = {
          kind = 'markdown',
          value = '_Translation domain_: ' .. translation_domain .. '\n_Value_: ' .. value
        },
      })
    end

    ::continue::
  end

  callback {
    items = items,
    isIncomplete = true,
  }
end

return source
