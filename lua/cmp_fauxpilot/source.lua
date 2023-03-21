local cmp = require('cmp')
local curl = require('plenary.curl')
local a = require('plenary.async')
local api = vim.api
local fn = vim.fn
local conf = require('cmp_fauxpilot.config')

local function dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end

local function escape_tabstop_sign(str)
  return str:gsub('%$', '\\$')
end

local function build_snippet(prefix, placeholder, suffix, add_final_tabstop)
  local snippet = escape_tabstop_sign(prefix) .. placeholder .. escape_tabstop_sign(suffix)
  if add_final_tabstop then
    return snippet .. '$0'
  else
    return snippet
  end
end

local Source = {
  job = '',
}
local last_instance = nil

function Source.new()
  last_instance = setmetatable({}, { __index = Source })
  return last_instance
end

function Source.is_available(self)
  return true
end

function Source.get_debug_name()
  return 'fauxpilot'
end

function Source._do_complete(self, ctx, callback)
  if self.job == 0 then
    return
  end
  local max_lines = conf:get('max_lines')
  local cursor = ctx.context.cursor
  local cur_line = ctx.context.cursor_line
  local cur_line_before = string.sub(cur_line, 1, cursor.col - 1)
  local cur_line_after = string.sub(cur_line, cursor.col) -- include current character

  local region_includes_beginning = false
  local region_includes_end = false
  if cursor.line - max_lines <= 1 then
    region_includes_beginning = true
  end
  if cursor.line + max_lines >= fn['line']('$') then
    region_includes_end = true
  end

  local lines_before = api.nvim_buf_get_lines(0, math.max(0, cursor.line - max_lines), cursor.line, false)
  table.insert(lines_before, cur_line_before)
  local before = table.concat(lines_before, '\n')

  local lines_after = api.nvim_buf_get_lines(0, cursor.line + 1, cursor.line + max_lines, false)
  table.insert(lines_after, 1, cur_line_after)
  local after = table.concat(lines_after, '\n')

  local req = {
    model = conf:get('model'),
    prompt = before,
    max_tokens = conf:get('max_tokens'),
    temperature = conf:get('temperature'),
    suffix = after,
  }
  local res = curl.post(conf:get('host') .. '/v1/engines/codegen/completions', {
    body = vim.fn.json_encode(req),
    headers = {
      content_type = 'application/json',
    },
  })

  local items = {}

  local data = vim.fn.json_decode(res.body)
  for _, result in ipairs(data.choices) do
    local newText = result.text

    if newText:find('.*\n.*') then
      -- this is a multi line completion.
      -- remove leading newlines
      newText = newText:gsub('^\n', '')
    end
    local range = {
      start = { line = cursor.line, character = cursor.col - result.index - 1 },
      ['end'] = { line = cursor.line, character = cursor.col + result.index - 1 },
    }

    local item = {
      label = newText,
      -- removing filterText, as it interacts badly with multiline
      -- filterText = newText,
      data = result,
      textEdit = {
        newText = newText,
        insert = range, -- May be better to exclude the trailing part of old_suffix since it's 'replaced'?
        replace = range,
      },
      sortText = newText,
      dup = 0,
    }
    if result.text:find('.*\n.*') then
      item['data']['multiline'] = true
      item['documentation'] = {
        kind = cmp.lsp.MarkupKind.Markdown,
        value = '```' .. (vim.filetype.match({ buf = 0 }) or '') .. '\n' .. newText .. '\n```',
      }
    end
    table.insert(items, item)
  end
  items = { unpack(items, 1, conf:get('max_num_results')) }
  callback({
    items = items,
    isIncomplete = conf:get('run_on_every_keystroke'),
  })
end

--- complete
function Source.complete(self, ctx, callback)
  self.job = ctx.context.id
  a.run(function()
    self:_do_complete(ctx, callback)
  end)
end

return Source
