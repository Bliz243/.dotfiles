" ============================================================================
" Basic Settings
" ============================================================================

" Use UTF-8 encoding
set encoding=utf-8

" Enable syntax highlighting
syntax on

" Enable filetype detection and plugins
filetype plugin indent on

" Set line numbers
set number
set relativenumber

" Enable mouse support
set mouse=a

" Set tabs and indents
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
set autoindent
set smartindent

" Highlight current line
set cursorline

" Enable true color support
set termguicolors

" Set clipboard to use system clipboard
set clipboard=unnamedplus

" Better command-line completion
set wildmenu
set wildmode=longest:full,full

" Search settings
set ignorecase
set smartcase
set incsearch
set hlsearch

" Show matching brackets
set showmatch

" No swap files
set noswapfile
set nobackup
set nowritebackup

" Better split behavior
set splitright
set splitbelow

" Update time for faster feedback
set updatetime=300

" Always show sign column
set signcolumn=yes

" Show command in bottom bar
set showcmd

" Wrap long lines
set wrap
set linebreak

" Scroll offset
set scrolloff=8
set sidescrolloff=8

" Better backspace behavior
set backspace=indent,eol,start

" Hide mode since we have a statusline
set noshowmode

" ============================================================================
" Plugin Manager: vim-plug
" ============================================================================

call plug#begin('~/.local/share/nvim/plugged')

" Core functionality
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'

" Fuzzy finding
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" File explorer
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'

" LSP and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Color schemes
Plug 'morhetz/gruvbox'
Plug 'folke/tokyonight.nvim'

" Language support
Plug 'sheerun/vim-polyglot'

" Auto pairs
Plug 'jiangmiao/auto-pairs'

" Indent guides
Plug 'Yggdroot/indentLine'

" Better whitespace
Plug 'ntpeters/vim-better-whitespace'

call plug#end()

" ============================================================================
" Color Scheme
" ============================================================================

set background=dark
colorscheme gruvbox
let g:gruvbox_contrast_dark = 'hard'
let g:gruvbox_sign_column = 'bg0'

" ============================================================================
" Plugin Configuration
" ============================================================================

" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.git$', '\.DS_Store$', 'node_modules']
let NERDTreeMinimalUI=1
" Auto-close NERDTree when opening a file
let NERDTreeQuitOnOpen=1

" FZF
nnoremap <C-p> :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>f :Rg<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>h :History<CR>
let g:fzf_layout = { 'down': '40%' }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']

" Airline
let g:airline_theme='gruvbox'
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter='unique_tail'
let g:airline#extensions#coc#enabled=1

" IndentLine
let g:indentLine_char = '▏'
let g:indentLine_first_char = '▏'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_conceallevel = 2

" GitGutter
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'

" Better Whitespace
let g:better_whitespace_enabled=1
let g:strip_whitespace_on_save=1
let g:strip_whitespace_confirm=0

" ============================================================================
" CoC Configuration
" ============================================================================

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code
xmap <leader>fm  <Plug>(coc-format-selected)
nmap <leader>fm  <Plug>(coc-format-selected)

" Apply codeAction to the selected region
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer
nmap <leader>ac  <Plug>(coc-codeaction)

" Apply AutoFix to problem on the current line
nmap <leader>qf  <Plug>(coc-fix-current)

" ============================================================================
" Key Mappings
" ============================================================================

" Set leader key
let mapleader = " "

" Save and quit shortcuts
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :wq<CR>

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize windows
nnoremap <silent> <C-Up> :resize +2<CR>
nnoremap <silent> <C-Down> :resize -2<CR>
nnoremap <silent> <C-Left> :vertical resize -2<CR>
nnoremap <silent> <C-Right> :vertical resize +2<CR>

" Buffer navigation
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Move lines up and down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Better indentation
vnoremap < <gv
vnoremap > >gv

" Copy to end of line
nnoremap Y y$

" Keep cursor centered when searching
nnoremap n nzzzv
nnoremap N Nzzzv

" Undo break points
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u

" Git shortcuts
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gp :Git push<CR>
nnoremap <leader>gl :Git pull<CR>
nnoremap <leader>gd :Gdiffsplit<CR>

" Quick source config
nnoremap <leader>so :source $MYVIMRC<CR>

" ============================================================================
" Language-Specific Settings
" ============================================================================

" JavaScript/TypeScript
autocmd FileType javascript,typescript,javascriptreact,typescriptreact setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Python
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4

" Go
autocmd FileType go setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab

" YAML
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Markdown
autocmd FileType markdown setlocal wrap linebreak

" Shell scripts
autocmd FileType sh setlocal tabstop=2 shiftwidth=2 softtabstop=2

" ============================================================================
" Auto Commands
" ============================================================================

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Return to last edit position when opening files
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Auto-reload files when changed externally
set autoread
autocmd FocusGained,BufEnter * checktime

" ============================================================================
" Performance
" ============================================================================

" Limit syntax highlighting for long lines
set synmaxcol=300

" Faster scrolling
set ttyfast
set lazyredraw

" ============================================================================
" CoC Extensions (auto-install)
" ============================================================================

let g:coc_global_extensions = [
  \ 'coc-json',
  \ 'coc-tsserver',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-python',
  \ 'coc-yaml',
  \ 'coc-sh',
  \ 'coc-docker',
  \ 'coc-markdownlint',
  \ 'coc-prettier',
  \ ]
