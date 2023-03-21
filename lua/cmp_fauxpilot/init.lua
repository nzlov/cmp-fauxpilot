local cmp = require('cmp')
local source = require('cmp_fauxpilot.source')

local M = {}

M.prefetch = function(self, file_path, count)
  count = (count or 1)
  if self.fauxpilot_source == nil and count < 5 then
    -- not initialized yet
    vim.schedule(function()
      self:prefetch(file_path, count + 1)
    end)
  else
    self.fauxpilot_source:prefetch(file_path)
  end
end

M.setup = function()
  vim.schedule(function()
    M.fauxpilot_source = source.new()
    cmp.register_source('cmp_fauxpilot', M.fauxpilot_source)
  end)
end

return M
