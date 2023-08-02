local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")

---@class Entry
---@field line_match LineMatch
---@field path_match PathMatch

---@param prompt string
---@return Entry[]
local sourcegraph_query = function(prompt)
  prompt = prompt or ""

  local results = require("sourcegraph").search_raw(prompt, -1)

  local entries = {}

  for _, result in ipairs(results.line_matches) do
    table.insert(entries, { line_match = result })
  end

  for _, result in ipairs(results.path_matches) do
    table.insert(entries, { path_match = result })
  end

  return entries
end

---comment
---@param entry Entry
---@return table
local sourcegraph_entry_maker = function(entry)
  local line_match = entry.line_match
  local path_match = entry.path_match

  if line_match ~= nil then
    return {
      value = line_match.content,
      display = function(_)
        local prefix = line_match.path .. ":" .. line_match.line .. ":" .. line_match.column .. ":"

        local highlights = {
          { { 0, #line_match.path },                                                     "Directory" },
          { { #line_match.path + 1, #line_match.path + 1 + #tostring(line_match.line) }, "LineNr" }
        }
        for _, highlight in ipairs(line_match.matches) do
          -- FIXME: trick to highlight matches, there might be a nicer way
          table.insert(
            highlights,
            { { #prefix + highlight.start, #prefix + highlight.stop }, "Search" }
          )
        end

        return prefix .. line_match.content, highlights
      end,
      ordinal = line_match.path .. line_match.content,
      filename = line_match.path,
      lnum = line_match.line,
      col = line_match.column,
    }
  end

  if path_match ~= nil then
    return {
      value = entry,
      display = function(_)
        local highlights = {
          { { 0, #path_match.path }, "Directory" }
        }
        for _, highlight in ipairs(path_match.matches) do
          table.insert(
            highlights,
            { { highlight.start, highlight.stop }, "Search" }
          )
        end

        return path_match.path, highlights
      end,
      ordinal = path_match.path,
      filename = path_match.path,
      lnum = 1,
    }
  end

  return {}
end

---@type fun(): string
local _query_prefix_function_wrapped = function()
  -- Placeholder function to return the sourcegraph query prefix
  -- It can be overriden by the user using setup function
  return ""
end

---@type fun(): string
local _query_prefix_function = function()
  -- Returns the prefix for sourcegraph query
  local result = _query_prefix_function_wrapped()
  assert(
    type(result) == string,
    "sourcegraph: query prefix function should return string, got " .. type(result) .. ": " .. result
  )

  return result
end

-- local sourcegraph_search = function(opts)
--   opts = opts or {}
--   pickers.new(opts, {
--     prompt_title = "SourceGraph Search",
--     previewer = config.values.grep_previewer(opts),
--     finder = finders.new_table {
--       results = sourcegraph_query("Foo"),
--       entry_maker = sourcegraph_entry_maker,
--     },
--   }):find()
-- end

---Live search SourceGraph with Telescope (queries are issued as you type)
---@param opts table
local sourcegraph_search_live = function(opts)
  opts = opts or {}

  local query_prefix = _query_prefix_function()
  local prompt_title_postfix = ""
  if #query_prefix > 0 then
    prompt_title_postfix = " (" .. query_prefix .. ")"
  end

  pickers.new(
    opts,
    {
      prompt_title = "SourceGraph Search" .. prompt_title_postfix,
      previewer = config.values.grep_previewer(opts),
      finder = finders.new_dynamic(
        {
          ---comment
          ---@param prompt string
          ---@return Entry[]
          fn = function(prompt)
            return sourcegraph_query(query_prefix .. " " .. prompt)
          end,
          entry_maker = sourcegraph_entry_maker,
        }
      ),
    }
  ):find()
end

---@class ExtConfig
---@field query_prefix_function fun(): string

-- TODO: cmp completion in telescope prompt

return require("telescope").register_extension {
  ---Setup the SourceGraph telescope extension
  ---Can provide an optional query_prefix_function param, which specifies
  ---a custom function, which will return a SourceGraph query prefix added
  ---to every SourceGraph request
  ---@param ext_config ExtConfig
  ---@return nil
  setup = function(ext_config)
    _query_prefix_function = ext_config.query_prefix_function or _query_prefix_function
  end,
  exports = {
    sourcegraph = sourcegraph_search_live
  },
}
