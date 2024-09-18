" Use UTF-8 encoding
set encoding=utf-8

" Enable syntax highlighting
syntax on

" Set line numbers
set number

" Enable mouse support
set mouse=a

" Set tabs and indents
set tabstop=4
set shiftwidth=4
set expandtab

" Set relative line numbers
set relativenumber

" Highlight current line
set cursorline

" Enable true color support
set termguicolors

" Set clipboard to use system clipboard
set clipboard=unnamedplus

" Plugin Manager: vim-plug
call plug#begin('~/.local/share/nvim/plugged')

" Plugins List
Plug 'tpope/vim-sensible'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'morhetz/gruvbox'

call plug#end()

" Configure NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>

" Configure fzf
nnoremap <C-p> :Files<CR>
