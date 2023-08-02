function s:git_repo_normalised()
    " Git repo path with protocol, user and '.git' suffix removed so it can be
    " sent to the sourcegraph to use as matching criteria for the repo
    let url = trim(system("git config --get remote.origin.url"))
    let url = substitute(url, '\.git$', '', '')
    let url = substitute(url, '.*@', '', '')
    let url = substitute(url, '.*:\/\/', '', '')
    let url = substitute(url, ':', '/', 'g')
    return url
endfunction

function s:git_latest_pushed_revision()
    " The latest revision, which has been pushed remotely, because obviously
    " sourcegraph doesn't know anything about our local commits
    return trim(system("git rev-parse --short @{push} 2>/dev/null || git rev-parse --short HEAD"))
endfunction

function sourcegraph#construct_local_repo_query()
    " Example function to construct a sourcegraph query to filter by the local
    " repo and the most recent pushed commit, which should be the most common
    " case

    " TODO: check if the revision exists remotely
    return 'repo:^' .. s:git_repo_normalised() .. '$' .. '@' .. s:git_latest_pushed_revision()
endfunction

function sourcegraph#fzf_search_opts(query)
    " Minimal working set of fzf options. User can copy paste this in case
    " they want to use custom paramters
    return {
    \   'source': v:lua.require("sourcegraph").search(a:query),
    \   'sink*': v:lua.require("sourcegraph").open_files,
    \   'options': ['--ansi', '--prompt', '> ', '--delimiter', ':', '--preview-window', '+{2}-/2']
    \ }
endfunction
