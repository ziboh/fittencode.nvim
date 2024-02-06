local api = vim.api
local fn = vim.fn

local Log = require('fittencode.log')

local M = {}

M.highlight = 'FittenSuggestion'

local function draw_virt_text(virt_text)
  if vim.tbl_count(virt_text) == 0 then
    return
  end

  api.nvim_buf_set_extmark(0, M.namespace, fn.line('.') - 1, fn.col('.') - 1, {
    virt_text = virt_text[1],
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })

  table.remove(virt_text, 1)

  if vim.tbl_count(virt_text) > 0 then
    api.nvim_buf_set_extmark(0, M.namespace, fn.line('.') - 1, 0, {
      virt_lines = virt_text,
    })
  end
end

local function clear_ns(namespace, bufnr)
  if namespace ~= nil and bufnr ~= nil then
    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
end

local function reset_ns()
  if M.namespace ~= nil then
    clear_ns(M.namespace, 0)
  else
    M.namespace = api.nvim_create_namespace('Fittencode')
  end
end

function M.clear_virt_text()
  clear_ns(M.namespace, 0)
end

local function move_center(virt_height)
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local relative_row = row - fn.line('w0') + 1
  local height = api.nvim_win_get_height(0)
  local center = math.floor(height / 2)
  if relative_row + virt_height > height and math.abs(relative_row - center) > 2 then
    -- Log.debug('relative_row: {}, virt_height: {}, height: {}, center: {}', relative_row, virt_height, height, center)
    local keys = vim.api.nvim_replace_termcodes('<Esc>zza', true, false, true)
    vim.api.nvim_feedkeys(keys, 'i', true)
  end
end

function M.render_virt_text(virt_text)
  if virt_text == nil then
    return
  end
  reset_ns()
  move_center(vim.tbl_count(virt_text))
  draw_virt_text(virt_text)
end

local autoindent = nil
local smartindent = nil
local formatoptions = nil
local textwidth = nil

local function local_fmt_clear()
  autoindent = vim.bo.autoindent
  smartindent = vim.bo.smartindent
  formatoptions = vim.bo.formatoptions
  textwidth = vim.bo.textwidth
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.formatoptions = ''
  vim.bo.textwidth = 0
end

local function local_fmt_recover()
  vim.bo.autoindent = autoindent
  vim.bo.smartindent = smartindent
  vim.bo.formatoptions = formatoptions
  vim.bo.textwidth = textwidth
end

function M.set_text(lines)
  local_fmt_clear()

  local row = fn.line('.') - 1
  local col = fn.col('.')
  local count = vim.tbl_count(lines)

  for i = 1, count, 1 do
    local line = lines[i]
    local len = string.len(line)
    if i == 1 then
      if len ~= 0 then
        api.nvim_buf_set_text(0, row, col - 1, row, col - 1, { line })
      end
    else
      local max = api.nvim_buf_line_count(0)
      if row + i - 1 >= max then
        api.nvim_buf_set_lines(0, max, max, false, { line })
      else
        api.nvim_buf_set_text(0, row + i - 1, 0, row + i - 1, 0, { line })
      end
    end
  end

  local first_len = string.len(lines[1])
  if count == 1 and first_len ~= 0 then
    api.nvim_win_set_cursor(0, { row + 1, col + first_len - 1 })
  else
    local last_len = string.len(lines[count])
    api.nvim_win_set_cursor(0, { row + count, last_len })
  end

  local keys = vim.api.nvim_replace_termcodes('<Esc>a', true, false, true)
  vim.api.nvim_feedkeys(keys, 'i', true)

  local_fmt_recover()
end

function M.setup_highlight()
  vim.api.nvim_set_hl(0, M.highlight, {
    link = 'Comment',
    default = true,
  })
end

return M
