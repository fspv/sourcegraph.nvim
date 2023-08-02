describe("vimscript tests", function()
  it("test repo query generated correctly", function()
    assert.matches(
      "^repo:.github.com.[a-zA-Z0-9]*.[a-zA-Z0-9]*.@[a-z0-9]*$",
      vim.api.nvim_eval("sourcegraph#construct_local_repo_query()")
    )
  end)
  it("test fzf options generated correctly", function()
    -- FIXME: this makes an actual query to the sourcegraph
    local fzf_opts = vim.api.nvim_eval("sourcegraph#fzf_search_opts('test123')")
    assert.is_table(fzf_opts)
  end)
end)

describe("lua utils test", function()
  local util = require("sourcegraph.util")

  it("test reverse table function", function()
    assert.same({ 3, 2, 1 }, util.reverse_table({ 1, 2, 3 }))
    assert.same({ 2, 3, 1 }, util.reverse_table({ 1, 3, 2 }))
    assert.same({}, util.reverse_table({}))
    assert.same({ 4 }, util.reverse_table({ 4 }))
    assert.same({ "1", "2" }, util.reverse_table({ "2", "1" }))
  end)

  it("test merge intervals", function()
    -- TODO: Add more test cases
    assert.same({ { start = 0, stop = 2 } }, util.merge_intervals({ { start = 0, stop = 1 }, { start = 1, stop = 2 } }))
    assert.same({ { start = 1, stop = 9 } }, util.merge_intervals({ { start = 3, stop = 9 }, { start = 1, stop = 2 } }))
    assert.same({}, util.merge_intervals({}))
  end)

  it("test url encode", function()
    -- TODO: test urlencode
  end)

  it("test to integer", function()
    assert.equal(1, util.tointeger("1"))
    assert.equal(1, util.tointeger(1))
    assert.equal(-11, util.tointeger("-11"))
  end)
end)

describe("lua parser test", function()
  local parse = require("sourcegraph.parse")

  it("test path line parser", function()
    assert.same({ filename = "a" }, parse._parse_match("a"))
    assert.same({ filename = "a", line = 123, column = 234 }, parse._parse_match("a:123:234:test"))
    assert.same({ filename = "a", line = 123, column = 234 }, parse._parse_match("a:123:234:test: int"))
  end)

  it("test path line parser", function()
    local matches = {
      {
        lineMatches = {
          {
            line = 'sample line content',
            lineNumber = 84,
            offsetAndLengths = { { 4, 2 }, { 9, 5 } }
          },
        },
        pathMatches = {
          {
            ["end"] = { column = 63, line = 0, offset = 63 },
            start = { column = 59, line = 0, offset = 59 }
          },
        },
        path = "sample/path",
        type = "content",
      }
    }
    assert.same(
      {
        {
          path = "sample/path",
          line = 85,
          column = 5,
          content = "sample line content",
          matches = {
            { start = 4, stop = 6 },
            { start = 9, stop = 14 }
          },
        }
      },
      parse.parse_sourcegraph_api_line_matches(matches)
    )
    assert.same(
      {
        {
          path = "sample/path",
          matches = {
            { start = 59, stop = 63 },
          },
        }
      },
      parse.parse_sourcegraph_api_path_matches(matches)
    )
    assert.same(
      {
        string.format(
          "%s[%smsample/path%s[%sm:%s[%sm85%s[%sm:5:samp%s[%smle%s[%sm li%s[%smne co%s[%smntent",
          string.char(27),
          35,
          string.char(27),
          0,
          string.char(27),
          32,
          string.char(27),
          0,
          string.char(27),
          31,
          string.char(27),
          0,
          string.char(27),
          31,
          string.char(27),
          0
        ),
        "sample/path"
      },
      parse.format_and_color_sourcegraph_api_matches(matches)
    )
  end)
end)

describe("lua e2e", function()
  local sourcegraph = require("sourcegraph")

  it("test basic query", function()
    local result = sourcegraph.search("test", -1)
    assert.is_table(result)
    assert.is_true(#result > 0)
  end)

  it("test basic query raw", function()
    local result = sourcegraph.search_raw("test", -1)
    assert.is_table(result)
    assert.is_true(#result.line_matches > 0)
    assert.is_true(#result.path_matches > 0)
    assert.is_true(#result.filters > 0)
  end)

  it("test basic query through api", function()
    local result = sourcegraph.api.search("https://sourcegraph.com/.api", nil, "test", -1)
    assert.is_table(result)
    assert.is_true(#result.filters > 0)
    assert.is_true(#result.matches > 0)
  end)
end)
