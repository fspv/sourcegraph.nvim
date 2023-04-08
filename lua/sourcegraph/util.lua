local M = {}

---Runtime type check
---@param param any
---@param expected_type type
M.assert_type = function(param, expected_type)
  assert(
    type(param) == expected_type,
    "sourcegraph: parameter should be a " .. expected_type .. ", got " .. type(param)
  )
end


---Runtime optional type check
---@param param any
---@param expected_type type
M.assert_optional_type = function(param, expected_type)
  if param == nil then
    return
  end
  M.assert_type(param, expected_type)
end


---Convert string to integer
---If not possible, crashes
---@param str string|integer
---@return integer
M.tointeger = function(str)
  ---@type number?
  local num = nil

  if type(str) == "number" then
    num = str
  else
    num = tonumber(str)
    M.assert_type(num, "number")
  end

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
M.url_encode = function(str)
  M.assert_type(str, "string")

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

---@class Interval
---@field start integer
---@field stop integer

---Merge intervals to ensure there no overlapping intervals
---Adjacent intervals are also merged. For example [1,3] + [4,9] -> [1,9]
---See corresponding [leetcode problem](https://leetcode.com/problems/merge-intervals/)
---@param intervals Interval[]
---@return Interval[]
M.merge_intervals = function(intervals)
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
M.reverse_table = function(data)
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

return M
