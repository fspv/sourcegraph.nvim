-- Global config to be used for application
-- Call setup() method in case you want to amend these values
local _config = {
    api_url = "https://sourcegraph.com/.api/search/stream",
    api_token = "",
}

local _url_encode = function(str)
    -- Url encode string
    -- :param str: String to encode
    -- :type str: string
    if type(str) ~= "string" then
        error("sourcegraph: url_encode parameter should be a string")
    end

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

local _search = function(query, display_limit)
    -- Search SourceGraph
    --
    -- Keyword parameters:
    -- :param query: A Sourcegraph query string (see search query syntax https://docs.sourcegraph.com/code_search/reference/queries)
    -- :type query: string
    -- :param display_limit: The maximum number of matches the backend
    --                       returns. Defaults to -1 (no limit). If the backend finds more
    --                       then display-limit results, it will keep searching and
    --                       aggregating statistics, but the matches will not be returned
    --                       anymore. Note that the display-limit is different from the query
    --                       filter count: which causes the search to stop and return once we
    --                       found count: matches.
    -- :type display_limit: number
    assert(type(query) == "string", "sourcegraph: query parameter should be a string")
    assert(
        display_limit == nil or type(display_limit) == "number",
        "sourcegraph: display_limit parameter should be a string"
    )

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
            elseif event == "done" then
                break
            else
                error("sourcegraph: unknown type of event " .. event)
            end
        else
            error("sourcegraph: unknown line from the API")
        end
    end

    print(vim.inspect.inspect(result))

    return result
end

local _filters_to_file = function(filters)
    assert(type(filters) == "table", "sourcegraph: filters show be a list")
end

local M = {
    setup = function(api_url, api_token)
        -- Initialise the plugin with custom parameters
        --
        -- Keyword arguments:
        -- :param api_url: Custom API url (default: https://sourcegraph.com/.api/search/stream)
        -- :type api_url: string
        -- :param api_token: Custom API token (default empty, there are some functions available without auth)
        -- :type api_token: string
        if type(api_url) ~= "string" then
            error("sourcegraph: api_url parameter should be a string")
        end

        if type(api_token) ~= "string" then
            error("sourcegraph: api_token parameter should be a string")
        end

        _config.sourcegraph_api_url = api_url
        _config.sourcegraph_api_token = api_token
    end,
    api = {
        search = _search,
        filters_to_file = _filters_to_file
    }
}

return M
