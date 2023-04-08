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
---`<path>:<line number>:<offset in line>:<line content>`
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

return M
