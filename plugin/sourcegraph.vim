" Title:        Query SourceGraph from Neovim
" Description:  Wrapper to call SourceGraph API from Neovim.
" Maintainer:   Pavel Safronov <https://github.com/fspv>

" Raw SourceGraph search query
command! -bang -nargs=* SourceGraphRaw call fzf#run(
\   fzf#wrap(
\     fzf#vim#with_preview(
\       sourcegraph#fzf_search_opts(<q-args>)
\     ),
\     <bang>0
\   )
\ )

" Predefined command to search a local git repo. User is not required to use
" it, this is just an example, the user can refer to
command! -bang -nargs=* SourceGraph call fzf#run(
\   fzf#wrap(
\     fzf#vim#with_preview(
\       sourcegraph#fzf_search_opts(
\         sourcegraph#construct_local_repo_query()
\         ..' ' .. <q-args>
\       )
\     ),
\     <bang>0
\   )
\ )

" Command to search a word under cursor in the source graph
map sg/ :SourceGraph <C-r><C-w><CR>
