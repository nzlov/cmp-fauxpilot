local M = {}

local conf_defaults = {
  host = 'http://localhost:5000',
  model = 'fastertransformer',
  max_tokens = 16,
  temperature = 0.6,
  top_p = 1,
  n = 1,
  echo = false,
  presence_penalty = 0,
  frequency_penalty = 1,
  best_of = 1,
  max_lines = 100,
  stop = { '\n' },
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
