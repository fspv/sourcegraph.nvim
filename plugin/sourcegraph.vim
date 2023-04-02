" Title:        Query SourceGraph from Neovim
" Description:  Wrapper to call SourceGraph API from Neovim.
" Last Change:  2 April 2023
" Maintainer:   Pavel Safronov <https://github.com/fspv>

command! -nargs=0 SourceGraphSearch lua require("sourcegraph").api.search("r:sourcegraph/sourcegraph doResults count:10", -1)
