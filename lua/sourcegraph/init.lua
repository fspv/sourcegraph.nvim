-- Global config to be used for application
-- Call setup() method in case you want to amend these values
local _config = {
  api_url = "https://sourcegraph.com/.api/search/stream",
  api_token = "",
}

---Runtime type check
---@param param any
---@param expected_type type
local _assert_type = function(param, expected_type)
  assert(
    type(param) == expected_type,
    "sourcegraph: parameter should be a " .. expected_type .. ", got " .. type(param)
  )
end


---Runtime optional type check
---@param param any
---@param expected_type type
local _assert_optional_type = function(param, expected_type)
  if param == nil then
    return
  end
  _assert_type(param, expected_type)
end


---Convert string to integer
---If not possible, crashes
---@param str string
---@return integer
local _tointeger = function(str)
  local num = tonumber(str)
  _assert_type(num, "number")

  if num == nil then
    error("Number cannot be nil")
  end

  local num_int = math.floor(num)

  if num_int ~= num then
    error("Number is not integer " .. num)
  end

  return num_int
end

---Url encode string
---@param str string # String to encode
---Retuns encoded string
---@return string
local _url_encode = function(str)
  _assert_type(str, "string")

  str = str:gsub("\r?\n", "\r\n")
  str = str:gsub(
    "([^%w%-%.%_%~ ])",
    function(c)
      return string.format("%%%02X", c:byte())
    end
  )
  str = str:gsub(" ", "+")

  return str
end

---Raw search SourceGraph query
---
---Returns a dictionary with two fields:
--- - filters: a list of suggested filters
--- - matches: a list of all the returned matches
---
---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
---@return Map
local _search = function(query, display_limit)
  _assert_type(query, "string")
  _assert_optional_type(display_limit, "number")

  print(vim.inspect.inspect(query))

  local curl = require("plenary.curl")

  local api_url = _config.api_url
  local api_token = _config.api_token

  local url = api_url .. "?q=" .. _url_encode(query)
  if display_limit ~= nil then
    url = url .. "&display=" .. display_limit
  end

  local headers = { accept = "text/event-stream" }

  if api_token ~= "" then
    headers.authorization = "token: " .. api_token
  end

  local out = curl.get(url, headers)

  assert(out ~= nil, "sourcegraph: no response from sourcegraph")
  assert(out.exit == 0, "sourcegraph: Error " .. out.exit .. " querying sourcegraph")

  -- Uncomment for debug
  -- print(vim.inspect.inspect(out))

  -- TODO: not sure how much of a good idea is it to concatenate filters and
  -- matches together, but I guess it is good enough for now. Will need to
  -- revisit this later, when I have more idea how it will be used
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
      elseif event == "alert" then
      elseif event == "done" then
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

--- @enum colors
local _COLORS = {
  cyan = 36,
  purple = 35,
  yellow = 33,
  green = 32,
  red = 31,
  none = 0,
}

---Color the entire string with the specified color
---@param color colors # Color to use
---@param str string # String to color
---@return string
local _color_string = function(color, str)
  _assert_type(color, "number")
  _assert_type(str, "string")

  return string.format("%s[%sm%s%s[%sm", string.char(27), color, str, string.char(27), 0)
end

---Color a part of the string specified by [start, stop)
---
---@param color colors # color code to use
---@param str string # string to color
---@param start integer # start of the color range (inclusive)
---@param stop integer # end of the color range (exclusive)
---@return string
local _color_string_range = function(color, str, start, stop)
  _assert_type(color, "number")
  _assert_type(str, "string")
  _assert_type(start, "number")
  _assert_type(stop, "number")

  -- In case instruction makes no sense return the string unmodified
  if start < 0 or start >= string.len(str) then
    return str
  end
  if stop < start then
    return str
  end

  -- In case stop is out of bounds, set it to the lenght of the string
  stop = math.min(stop, string.len(str))

  return string.sub(str, 0, start)
      .. _color_string(color, string.sub(str, start + 1, stop))
      .. string.sub(str, stop + 1)
end

---@class Interval
---@field start integer
---@field stop integer

---Merge intervals to ensure there no overlapping intervals
---Adjacent intervals are also merged. For example [1,3] + [4,9] -> [1,9]
---See corresponding [leetcode problem](https://leetcode.com/problems/merge-intervals/)
---@param intervals Interval[]
---@return Interval[]
local _merge_intervals = function(intervals)
  if #intervals == 0 then
    return intervals
  end

  ---@type Interval[]
  local result = {}

  --Sort intervals by [start, stop]
  table.sort(intervals, function(left, right)
    if left.start == right.start then
      return left.stop <= right.stop
    end
    return left.start < right.start
  end
  )

  table.insert(result, intervals[1])

  for _, interval in ipairs(intervals) do
    if result[#result].stop + 1 < interval.start then
      -- Add a new interval (not overlapping with previous)
      table.insert(result, interval)
    else
      -- Extend the right boundary of the previous overlapping interval
      result[#result].stop = interval.stop
    end
  end

  return result
end

---Reverse a table
---@generic T
---@param data T[]
---@return T[]
local _reverse_table = function(data)
  local left = 1
  local right = #data
  while left < right do
    local tmp = data[right]
    data[right] = data[left]
    data[left] = tmp
    left = left + 1
    right = right - 1
  end

  return data
end

---Given the color, string and intervals to highlight, brush those intervals into a specified color
---Intervals may be overlapping and can go in arbitrary order
---@param color colors # Color to use
---@param str string # String to highlight
---@param intervals Interval[] # Intervals to highlight in arbitrary order
---@return string
local _color_intervals = function(color, str, intervals)
  -- Merge matches to ensure there are no overlapping highlights
  intervals = _merge_intervals(intervals)
  -- Reverse to facilitate highlighting (with forward order should keep track of inserted chars)
  intervals = _reverse_table(intervals)

  for _, interval in ipairs(intervals) do
    str = _color_string_range(color, str, interval.start, interval.stop)
  end

  return str
end

---Process a single line match and return a formatted string
---Example line match:
---```
---{
---  line = 'sample line content',
---  lineNumber = 84,
---  offsetAndLengths = { { 4, 2 }, { 9, 5} }
---}
---```
---@param path string
---@param line_match table
---@return string
local _process_line_matches = function(path, line_match)
  -- +1 since vim counts lines starting from 1
  local line_number = _tointeger(line_match.lineNumber) + 1
  ---@type string
  local content = line_match.line

  ---@type Interval[]
  local interval_match = {}
  local column = string.len(content)

  ---@type string[]
  for _, offset_and_length in ipairs(line_match.offsetAndLengths) do
    local offset = _tointeger(offset_and_length[1])

    local length = _tointeger(offset_and_length[2])
    table.insert(interval_match, { start = offset, stop = offset + length })

    -- +1 since vim counts columns starting from 1
    -- We highlight multiple matches, but will return only the first column to
    -- avoid returning multiple resules for the same string
    column = math.min(offset + 1, column)
  end

  return _color_string(_COLORS.purple, path) ..
      ':' .. _color_string(_COLORS.green, string.format("%d", line_number)) ..
      ':' .. column ..
      ':' .. _color_intervals(_COLORS.red, content, interval_match)
end

---Process a single path match and return a formatted string
---Example path match:
---```
---{
---  ["end"] = { column = 63, line = 0, offset = 63 }
---  start = { column = 59, line = 0, offset = 59 }
---},
---```
---@param path string
---@param path_matches table
---@return string
local _process_path_matches = function(path, path_matches)
  ---@type Interval[]
  local interval_matches = {}

  for _, path_match in ipairs(path_matches) do
    ---@type Interval
    local interval_match = { start = path_match.start.column, stop = path_match["end"].column }
    table.insert(interval_matches, interval_match)
  end

  return _color_intervals(_COLORS.red, path, interval_matches)
end

---Convert matches returned by SourceGraph in the common parseable format
---Accepts matches in the following format:
--- ```
--- {
---   {
---     lineMatches = {
---       {
---         line = 'sample line content',
---         lineNumber = 84,
---         offsetAndLengths = { { 4, 2 }, { 9, 5} }
---       },
---     },
---     pathMatches = {
---       {
---         ["end"] = { column = 63, line = 0, offset = 63 }
---         start = { column = 59, line = 0, offset = 59 }
---       },
---     },
---     path = "sample/path",
---     type = "content"
--- }
--- ```
---
---Output is a list of lines in the following format
---`<path>:<line number>:<offset in line>:<line content>`
---
---@param matches table
---@return string[]
local _matches_to_file = function(matches)
  _assert_type(matches, "table")

  ---@type string[]
  local results = {}

  for _, match in ipairs(matches) do
    local path = match.path

    local line_matches = match.lineMatches
    local path_matches = match.pathMatches

    if line_matches ~= nil then
      for _, line_match in ipairs(line_matches) do
        table.insert(results, _process_line_matches(path, line_match))
      end
    end

    if path_matches ~= nil then
      table.insert(results, _process_path_matches(path, path_matches))
    end
  end

  return results
end

local M = {
  -- Top level functions are the ones that user usually wants to call

  ---Initialise the plugin with custom parameters
  ---@param api_url string # Custom API url (default: `https://sourcegraph.com/.api/search/stream`)
  ---@param api_token string # Custom API token (default empty, there are some functions available without auth)
  setup = function(api_url, api_token)
    _assert_type(api_url, "string")
    _assert_type(api_token, "string")

    _config.sourcegraph_api_url = api_url
    _config.sourcegraph_api_token = api_token
  end,
  ---Wrapper around raw API search results into strings that many of the tools understand
  ---Output is a list of lines in the following format
  ---`<path>:<line number>:<offset in line>:<line content>`
  ---
  ---@param query string  # A Sourcegraph query string (see [search query syntax](https://docs.sourcegraph.com/code_search/reference/queries))
  ---@param display_limit  number  # The maximum number of matches the backend returns. Defaults to -1 (no limit).
  ---@return string[]
  search = function(query, display_limit)
    return _matches_to_file(_search(query, display_limit).matches)
  end,
  api = {
    -- Functions returning raw API responses to implement custom user functionality
    search = _search,
  }
}

return M
