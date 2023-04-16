local M = {}

local util = require("sourcegraph.util")
local color = require("sourcegraph.color")

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
---@param line_match SourceGraphAPILineMatch
---@return string
local process_line_matches = function(path, line_match)
  -- +1 since vim counts lines starting from 1
  local line_number = util.tointeger(line_match.lineNumber) + 1
  ---@type string
  local content = line_match.line

  ---@type Interval[]
  local interval_match = {}
  local column = string.len(content)

  ---@type string[]
  for _, offset_and_length in ipairs(line_match.offsetAndLengths) do
    local offset = util.tointeger(offset_and_length[1])

    local length = util.tointeger(offset_and_length[2])
    table.insert(interval_match, { start = offset, stop = offset + length })

    -- +1 since vim counts columns starting from 1
    -- We highlight multiple matches, but will return only the first column to
    -- avoid returning multiple resules for the same string
    column = math.min(offset + 1, column)
  end

  return color.color_string(color.COLORS.purple, path) ..
      ':' .. color.color_string(color.COLORS.green, string.format("%d", line_number)) ..
      ':' .. column ..
      ':' .. color.color_intervals(color.COLORS.red, content, interval_match)
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
---@param path_matches SourceGraphAPIPathMatch[]
---@return string
local process_path_matches = function(path, path_matches)
  ---@type Interval[]
  local interval_matches = {}

  for _, path_match in ipairs(path_matches) do
    ---@type Interval
    local interval_match = { start = path_match.start.column, stop = path_match["end"].column }
    table.insert(interval_matches, interval_match)
  end

  return color.color_intervals(color.COLORS.red, path, interval_matches)
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
---`<path>` - in case of a match in a file path
---`<path>:<line number>:<offset in line>:<line content>` - in case of content match in the file
---
---@param matches SourceGraphAPIMatch[]
---@return string[]
M.sourcegraph_api_matches_to_files = function(matches)
  util.assert_type(matches, "table")

  ---@type string[]
  local results = {}

  for _, match in ipairs(matches) do
    local path = match.path

    local line_matches = match.lineMatches
    local path_matches = match.pathMatches

    if line_matches ~= nil then
      for _, line_match in ipairs(line_matches) do
        table.insert(results, process_line_matches(path, line_match))
      end
    end

    if path_matches ~= nil then
      table.insert(results, process_path_matches(path, path_matches))
    end
  end

  return results
end

---@class Match
---@field filename string
---@field line integer|nil
---@field column integer|nil


---Parse path returned by `sourcegraph_api_matches_to_files` method
---
---@param path string  # Path to parse
---@return Match
M._parse_match = function(path)
  util.assert_type(path, "string")

  ---Parsed params from path
  ---@type string[]
  local params = {}

  for param in (path .. ":"):gmatch("([^:]*):") do
    table.insert(params, param)
  end

  -- It should be either a path match, in which case only file path should be
  -- returned
  -- Otherwise it should contain at least <path>:<line>:<column>:<content>,
  -- where content might contain colons on its own, hence ">4"
  assert(#params == 1 or #params >= 4, "sourcegraph: malformed path: " .. path .. " has " .. #params .. " fields")

  -- Filename should be always present
  -- TODO escape filename
  local filename = params[1]

  if #params == 1 then
    -- Path match, nothing else left to do
    return { filename = filename }
  end

  -- Check if line and column is provided
  local line = util.tointeger(params[2])
  local column = util.tointeger(params[3])

  assert(line >= 0 and column >= 0, "sourcegraph: inccorect values for line and column: " .. line .. ", " .. column)

  return { filename = filename, line = line, column = column }
end

---Open file using the path returned from the `sourcegraph_api_matches_to_files` method
---
---@param path string # Either a path to the file or a colon separated list of fields as expected to be returned from the `sourcegraph_api_matches_to_files` method
---@param cmd string  # Command to open file ("e" by default)
M.open_file_from_match = function(path, cmd)
  util.assert_type(path, "string")
  util.assert_type(cmd, "string")

  local match = M._parse_match(path)

  -- Open file
  vim.cmd(cmd .. " " .. match.filename)

  local line = match.line
  local column = match.column

  -- In case line and column are specified, try to move cursor there
  if line ~= nil and column ~= nil then
    vim.api.nvim_win_set_cursor(0, { line, column - 1 })
  end
end

return M
