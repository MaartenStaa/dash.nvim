local M = {}

local cached_results = {}

local function handle_selected(selected)
  if not selected or #selected ~= 1 or not cached_results or #cached_results < 1 then
    return
  end

  local matching_items = vim.tbl_filter(function(item)
    return item.display == selected[1]
  end, cached_results)
  if not matching_items or #matching_items < 1 then
    return
  end
  local selected_item = matching_items[1]
  local libdash = require('libdash_nvim')
  if selected_item.is_fallback then
    libdash.open_url(selected_item.value)
  else
    libdash.open_item(selected_item)
  end
end

local default_opts = {
  exec_empty_query = true,
  bang = false,
  actions = {
    default = handle_selected,
  },
}

M.dash = function(opts)
  local fzf_lua = require('fzf-lua')
  opts = fzf_lua.config.normalize_opts(opts, default_opts)
  if not opts then
    return
  end

  opts.query = opts.initial_text or ''
  opts.prompt = 'Dash> '
  opts.fzf_opts = {
    ['--header'] = vim.fn.shellescape(require('dash.providers').build_picker_title(opts.bang or false)),
  }

  -- This gets called whenever input is changed
  -- Also gets called first run if `opts.exec_empty_query == true`
  local current_file_type = vim.bo.filetype
  fzf_lua.fzf_live(function(query)
    if not query or #query == 0 then
      return {}
    end

    cached_results = require('libdash_nvim').query({
      search_text = query,
      buffer_type = current_file_type,
      ignore_keywords = opts.bang or false,
    })
    local items = {}
    for _, item in pairs(cached_results) do
      table.insert(items, item.display)
    end
    return items
  end, opts)
end

return M
