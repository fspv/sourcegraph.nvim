# SourceGraph for NeoVIM
Query SourceGraph from NeoVIM, display search results and open local files directly from search.

![input (1)](https://user-images.githubusercontent.com/1616237/232343594-61e26f68-3b15-4ce8-bbd1-48afc854cd4a.gif)



# Installation
This plugin has a hard dependency on [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) since standard nvim lua library can't make web requests. So install together those two plugins together.

Also for quickstart you can install [fzf](https://github.com/junegunn/fzf.vim) plugin, for which there are basic commands predefined already.

## Minimal setup
Using [plug](https://github.com/junegunn/vim-plug):
```vimscript
Plug 'nvim-lua/plenary.nvim'
Plug 'fspv/sourcegraph.nvim'
```

## Recommended setup
Using [plug](https://github.com/junegunn/vim-plug):
```vimscript
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } 
Plug 'junegunn/fzf.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'fspv/sourcegraph.nvim'
```

TODO: add [packer](https://github.com/wbthomason/packer.nvim) instructios

# Quickstart
Assumptions before starting using the plugin:
* You're using a git repo
* Your repo is indexed by the SourceGraph instance (either public or a private one)
* Your current nvim cwd is the root of the repo you're trying to search
* You have used recommended setup from the installation section
* Sourcegraph knows your repo with the same path that is returned by `git remote -v` (excluding .git suffix, username and protocol)
* Git upstream for the current branch is set to the branch, which contains commits, indexed by sourcegraph (otherwise, reset it with `git branch --set-upstream-to`)

Those assumptions should be the most common case, if you're already using sourcegraph with your repo, so just give it a go.

To search anything in the current repository, just enter:

```
:SourceGraph query123
```

If that worked, you've set up everything correctly, enjoy. You can also use `sg/` shortcut to search a word under cursor.

In case that doesn't work, try the version, which doesn't add any git-related parameters
```
:SourceGraphRaw query123
```

# Custom repo

Setting up a custom repo is as easy as calling
```
lua << EOF
require("sourcegraph").setup(
  {
    api_url = "https://sourcegraph.yourdomain.com/.api",
    api_token = "abcde"
  }
)
EOF
```

# TODO
- [ ] Add lsp to complete search
