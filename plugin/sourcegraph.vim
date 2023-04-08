" Title:        Query SourceGraph from Neovim
" Description:  Wrapper to call SourceGraph API from Neovim.
" Last Change:  2 April 2023
" Maintainer:   Pavel Safronov <https://github.com/fspv>

" command! -nargs=0 SourceGraphSearch lua require("sourcegraph").api.matches_to_file(require("sourcegraph").api.search("r:sourcegraph/sourcegraph doResults count:10", -1).matches)
"


command! -bang -nargs=* SourceGraphLocalGitRepoContent call fzf#run(
\   fzf#wrap(
\     fzf#vim#with_preview(
\       sourcegraph#fzf_search_opts(
\         sourcegraph#construct_local_repo_query()
\         ..' type:file '
\         .. <q-args>
\       )
\     ),
\     <bang>0
\   )
\ )

command! -bang -nargs=* SourceGraphLocalGitRepoFiles call fzf#run(
\   fzf#wrap(
\     fzf#vim#with_preview(
\       sourcegraph#fzf_search_opts(
\         sourcegraph#construct_local_repo_query()
\         ..' type:path '
\         .. <q-args>
\       )
\     ),
\     <bang>0
\   )
\ )
