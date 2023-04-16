call plug#begin()
  " To display search results in fzf windows
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  " Contains a function to fetch http url
  Plug 'nvim-lua/plenary.nvim'
  " Local copy of a plugin
  Plug '/src/sourcegraph.nvim'
call plug#end()

lua << EOF
require("sourcegraph").setup(
  {
    api_url = "https://sourcegraph.com/.api",
    api_token = ""
  }
)
EOF
