local M = {}

local util = require("sourcegraph.util")

---@enum MatchType
M.MatchType = {
  content = "content"
}

---@class SourceGraphAPIFilter
---@field count integer # Example: 20
---@field kind string # Example: "lang"
---@field label string # Example: "JavaScript"
---@field limitHit boolean # Example: false
---@field value string # Example: "lang:javascript"

---@class SourceGraphAPILineMatch
---@field line string # File line content
---@field lineNumber integer # Example: 354
---@field offsetAndLengths integer[][] # Example: { { 10, 4 }, {31, 5} }
--
---@class SourceGraphAPIPathMatchPos
---@field column integer # Example: 123
---@field line integer # Always 0 for path match
---@field offset integer # Always equal to column for path match

---@class SourceGraphAPIPathMatch
---@field start SourceGraphAPIPathMatchPos # File line content
---@field end SourceGraphAPIPathMatchPos # File line content

---@class SourceGraphAPIMatch
---@field branches string[] # Example: { "dd5365878da2fe88a34dcdbb07d8297a78841da4" }
---@field commit string # Example: "dd5365878da2fe88a34dcdbb07d8297a78841da4"
---@field hunks nil # Example: vim.NIL
---@field path string # Example: "src/util/file.py"
---@field repoLastFetched string # Example: "2023-04-08T18:26:53.10011Z"
---@field repoStars integer # Example: 205499
---@field repository string # Example: "github.com/facebook/react"
---@field repositoryID string # Example: 12345
---@field type MatchType # Example: "content"
---@field lineMatches SourceGraphAPILineMatch[]
---@field pathMatches SourceGraphAPIPathMatch[]

---@class SourceGraphAPISearchResult
---@field filters SourceGraphAPIFilter[]
---@field matches SourceGraphAPIMatch[]

---Raw search SourceGraph query
---
---Returns a dictionary with two fields:
--- - filters: a list of suggested filters
--- - matches: a list of all the returned matches
---
---@param api_url string # API url, for example `https://sourcegraph.com/.api/search/stream`
---@param api_token string? # API token. Can be nil in case API is open for everyone
---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
---@return SourceGraphAPISearchResult
M.search = function(api_url, api_token, query, display_limit)
  util.assert_type(api_url, "string")
  util.assert_optional_type(api_token, "string")
  util.assert_type(query, "string")
  util.assert_optional_type(display_limit, "number")

  print(vim.inspect.inspect(query))

  local curl = require("plenary.curl")

  local url = api_url .. "/search/stream?q=" .. util.url_encode(query)
  if display_limit ~= nil then
    url = url .. "&display=" .. display_limit
  end

  local headers = { accept = "text/event-stream" }

  if api_token ~= "" and api_token ~= nil then
    headers.authorization = "token " .. api_token
  end

  local out = curl.get(url, { headers = headers })

  assert(out ~= nil, "sourcegraph: no response from sourcegraph")
  assert(out.exit == 0, "sourcegraph: Error " .. out.exit .. " querying sourcegraph")
  assert(out.status == 200, "sourcegraph: Got code " .. out.status .. " querying sourcegraph. Response: " .. out.body)

  -- Uncomment for debug
  -- print(vim.inspect.inspect(out))

  -- TODO: not sure how much of a good idea is it to concatenate filters and
  -- matches together, but I guess it is good enough for now. Will need to
  -- revisit this later, when I have more idea how it will be used
  ---@type SourceGraphAPISearchResult
  local result = {
    filters = {},
    matches = {},
  }

  -- Iterate over response string
  local event = ""
  for key, value in string.gmatch(out.body, "([a-z]+): ([^\n]*)") do
    if key == "event" then
      event = value
    elseif key == "data" then
      if event == "filters" then
        ---@type SourceGraphAPIFilter
        local filters = vim.json.decode(value)
        for _, filter in ipairs(filters) do
          table.insert(result.filters, filter)
        end
      elseif event == "matches" then
        local matches = vim.json.decode(value)
        for _, match in ipairs(matches) do
          table.insert(result.matches, match)
        end
      elseif event == "progress" then
        -- TODO: Not implemented
      elseif event == "alert" then
        -- TODO: Not implemented
      elseif event == "done" then
        -- According to the docs should be the last event
        break
      else
        error("sourcegraph: unknown type of event " .. event)
      end
    else
      error("sourcegraph: unknown line from the API")
    end
  end

  return result
end

return M
