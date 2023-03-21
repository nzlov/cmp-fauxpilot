local M = {}

local conf_defaults = {
  host = 'http://localhost:5000',
  model = 'py-model',
  max_tokens = 100,
  max_lines = 1000,
  max_num_results = 4,
  temperature = 0.6,
}

function M:setup(params)
  for k, v in pairs(params or {}) do
    conf_defaults[k] = v
  end
end

function M:get(what)
  return conf_defaults[what]
end

return M
