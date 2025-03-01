local M = {}

function M.get_text_before_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]
  local cursor_column = cursor[2]

  cursor_line = vim.fn.getline(cursor_line)

  return cursor_line:sub(1, cursor_column)
end

return M
