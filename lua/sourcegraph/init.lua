---@module "sourcegraph.api"
---@module "sourcegraph.util"
local util = require("sourcegraph.util")
local parse = require("sourcegraph.parse")
local api = require("sourcegraph.api")

---Global config to be used for application
---Call setup() method in case you want to amend these values
---@class Config
---@field api_url string # API url (default: `https://sourcegraph.com/.api/search/stream`)
---@field api_token string|nil # API token (can be empty, there are some functions available without auth)
---@field open_file_cmd string # Vimscript command to be used for opening files
local _config = {
  api_url = "https://sourcegraph.com/.api",
  api_token = nil,
  open_file_cmd = "e",
}

---@class RawSearchResult
---@field line_matches LineMatch[]
---@field path_matches PathMatch[]
---@field filters Filter[]

local M = {
  -- Top level functions are the ones that user usually wants to call
  ---Initialise the plugin with custom parameters
  ---
  ---@param config Config
  setup = function(config)
    local api_url = config.api_url
    local api_token = config.api_token
    local open_file_cmd = config.open_file_cmd

    util.assert_optional_type(api_url, "string")
    util.assert_optional_type(api_token, "string")
    util.assert_optional_type(open_file_cmd, "string")

    if api_url ~= nil then
      _config.api_url = api_url
    end
    if api_token ~= nil then
      _config.api_token = api_token
    end
    if open_file_cmd ~= nil then
      _config.open_file_cmd = open_file_cmd
    end
  end,
  ---Wrapper around raw API search results into strings that many of the tools understand
  ---Output is a list of lines in the following format
  ---`<path>` - in case of a match in a file path
  ---`<path>:<line number>:<offset in line>:<line content>` - in case of content match in the file
  ---
  ---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
  ---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
  ---@return string[]
  search = function(query, display_limit)
    return parse.format_and_color_sourcegraph_api_matches(
      api.search(_config.api_url, _config.api_token, query, display_limit).matches
    )
  end,
  ---Wrapper around raw API search results converting them into the
  ---`LineMatch` and `PathMatch` objects, so they can later be used
  ---to create custom logic on top
  ---TODO: add objects description
  ---
  ---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
  ---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
  ---@return RawSearchResult
  search_raw = function(query, display_limit)
    local result = api.search(_config.api_url, _config.api_token, query, display_limit)
    return {
      line_matches = parse.parse_sourcegraph_api_line_matches(result.matches),
      path_matches = parse.parse_sourcegraph_api_path_matches(result.matches),
      filters = parse.parse_sourcegraph_api_filters(result.filters)
    }
  end,
  ---Open files using the path returned from the `search` method
  ---
  ---@param paths string[]  # Table of either a paths to the file or a colon separated lists of fields as expected to be returned from the `search` method
  open_files = function(paths)
    util.assert_type(paths, "table")

    -- TODO check if opening multiple files actually works
    for _, path in ipairs(paths) do
      parse.open_file_from_match(path, _config.open_file_cmd)
    end
  end,
  api = {
    -- Functions returning raw API responses to implement custom user functionality
    search = api.search,
  }
}

return M
