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
    return trim(system("git rev-parse @{push}"))
endfunction

function! s:open_file_by_match_line(lines)
    " Function similar to the one, that exists in fzf.vim to open files from
    " string in format '<path>:<line number>:<column number>:<content>'
    " It is just a very basic reconstruction of what's present in fzf.vim, so
    " it won't handle windows and other exotic edge cases, so needs proper
    " work on this in the future. So far it exists just to prove the concept.
    "
    if len(a:lines) != 1
    then
        " The function doesn't really handle all the lines, just the first one
        " (I'm not sure what are the situations, where we want to handle more,
        " though)
        return
    endif

    let cmd = 'e'

    let parts = split(a:lines[0], ':')

    " TODO: handle windows, etc
    let filename = &acd ? fnamemodify(parts[0], ':p') : parts[0]
    try
        " TODO: escaping the filename
        execute cmd filename
    catch
    endtry

    " If just a filename provided, return early
    if len(parts) == 1
        return
    endif

    " If exact location in the file is provided, go there
    let line_numer = parts[1]
    let column = parts[2]

    try
        execute line_numer
        call cursor(0, column)
        normal! zvzz
    catch
    endtry
endfunction

function sourcegraph#construct_local_repo_query()
    return 'repo:^' .. s:git_repo_normalised() .. '$' .. ' rev:' .. s:git_latest_pushed_revision()
endfunction

function sourcegraph#fzf_search(query, bang)
    call fzf#run(
    \  fzf#wrap(
    \    fzf#vim#with_preview(
    \      {
    \        'source': v:lua.require("sourcegraph").search(a:query),
    \        'sink*': function('s:open_file_by_match_line'),
    \        'options': ['--ansi', '--prompt', '> ',
    \                   '--delimiter', ':', '--preview-window', '+{2}-/2']
    \      },
    \    )
    \  ),
    \  a:bang
    \)
endfunction

function! sourcegraph#fzf_local_git_repo(query, bang)
    call sourcegraph#fzf_search(sourcegraph#construct_local_repo_query() .. ' ' .. a:query, a:bang)
endfunction

function! sourcegraph#fzf_local_git_repo_content(query, bang)
    call sourcegraph#fzf_local_git_repo('type:file ' .. a:query, a:bang)
endfunction

function! sourcegraph#fzf_local_git_repo_files(query, bang)
    call sourcegraph#fzf_local_git_repo('type:path ' .. a:query, a:bang)
endfunction
