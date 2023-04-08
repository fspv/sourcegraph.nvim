local M = {}

local util = require("sourcegraph.util")

--- @enum colors
M.COLORS = {
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
M.color_string = function(color, str)
  util.assert_type(color, "number")
  util.assert_type(str, "string")

  return string.format("%s[%sm%s%s[%sm", string.char(27), color, str, string.char(27), 0)
end

---Color a part of the string specified by [start, stop)
---
---@param color colors # color code to use
---@param str string # string to color
---@param start integer # start of the color range (inclusive)
---@param stop integer # end of the color range (exclusive)
---@return string
M.color_string_range = function(color, str, start, stop)
  util.assert_type(color, "number")
  util.assert_type(str, "string")
  util.assert_type(start, "number")
  util.assert_type(stop, "number")

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
      .. M.color_string(color, string.sub(str, start + 1, stop))
      .. string.sub(str, stop + 1)
end

---Given the color, string and intervals to highlight, brush those intervals into a specified color
---Intervals may be overlapping and can go in arbitrary order
---@param color colors # Color to use
---@param str string # String to highlight
---@param intervals Interval[] # Intervals to highlight in arbitrary order
---@return string
M.color_intervals = function(color, str, intervals)
  -- Merge matches to ensure there are no overlapping highlights
  intervals = util.merge_intervals(intervals)
  -- Reverse to facilitate highlighting (with forward order should keep track of inserted chars)
  intervals = util.reverse_table(intervals)

  for _, interval in ipairs(intervals) do
    str = M.color_string_range(color, str, interval.start, interval.stop)
  end

  return str
end

return M
