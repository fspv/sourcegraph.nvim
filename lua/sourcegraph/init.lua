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
local _config = {
  api_url = "https://sourcegraph.com/.api/search/stream",
  api_token = nil,
}

local M = {
  -- Top level functions are the ones that user usually wants to call

  ---Initialise the plugin with custom parameters
  ---@param api_url string # Custom API url (default: `https://sourcegraph.com/.api/search/stream`)
  ---@param api_token string # Custom API token (default empty, there are some functions available without auth)
  setup = function(api_url, api_token)
    util.assert_type(api_url, "string")
    util.assert_type(api_token, "string")

    _config.api_url = api_url
    _config.api_token = api_token
  end,
  ---Wrapper around raw API search results into strings that many of the tools understand
  ---Output is a list of lines in the following format
  ---`<path>:<line number>:<offset in line>:<line content>`
  ---
  ---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
  ---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
  ---@return string[]
  search = function(query, display_limit)
    return parse.sourcegraph_api_matches_to_files(
      api.search(_config.api_url, _config.api_token, query, display_limit).matches
    )
  end,
  api = {
    -- Functions returning raw API responses to implement custom user functionality
    search = api.search,
  }
}

return M
