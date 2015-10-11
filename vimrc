" vim: fdm=marker ts=2 sts=2 sw=2 fdl=2 expandtab

" detect environment/runtime {{{
  let s:is_unix = has('unix')
  let s:is_windows = has('win32') || has('win64')
  let s:is_cygwin = has('win32unix')
  let s:is_mac = has('mac')
  let s:is_nvim = has('nvim')
  let s:has_ack = executable('ack')
  let s:has_ag = executable('ag')
" }}}

" dotvim settings {{{
  if !exists('g:dotvim_settings') || !exists('g:dotvim_settings.version')
    echom 'The g:dotvim_settings and g:dotvim_settings.version variables must be defined.'
    finish
  endif

  let s:vim_dir = s:is_nvim ? '~/.nvim' : '~/.vim'
  let s:cache_dir = get(g:dotvim_settings, 'cache_dir', s:vim_dir . '/.cache')

  if g:dotvim_settings.version != 2
    echom 'This version number in your shim does not match the distribution version.'
    finish
  endif

  " initialize default settings
  let s:settings = {}
  let s:settings.default_indent = 2
  let s:settings.max_column = 120
  let s:settings.enable_cursorcolumn = 0
  let s:settings.colorscheme = 'gruvbox'

  if exists('g:dotvim_settings.plugin_groups')
    let s:settings.plugin_groups = g:dotvim_settings.plugin_groups
  else
    let s:settings.plugin_groups = []
    call add(s:settings.plugin_groups, 'core')
    call add(s:settings.plugin_groups, 'go')
    call add(s:settings.plugin_groups, 'scm')
    call add(s:settings.plugin_groups, 'navigation')
    call add(s:settings.plugin_groups, 'unite')
    call add(s:settings.plugin_groups, 'autocomplete')
    call add(s:settings.plugin_groups, 'misc')
  endif

  " override defaults with the ones specified in g:dotvim_settings
  for key in keys(s:settings)
    if has_key(g:dotvim_settings, key)
      let s:settings[key] = g:dotvim_settings[key]
    endif
  endfor
" }}}

" setup {{{
  set nocompatible
  set all& " reset everything to their defaults
  if s:is_windows
    set rtp+=s:vim_dir
  endif
" }}}

" functions {{{
  function! s:get_vim_dir(suffix) " {{{
    return resolve(expand(s:vim_dir . '/' . a:suffix))
  endfunction " }}}

  function! s:get_cache_dir(suffix) " {{{
    return resolve(expand(s:cache_dir . '/' . a:suffix))
  endfunction " }}}

  function! s:ensure_dir_exists(path) " {{{
    if !isdirectory(expand(a:path))
      call mkdir(expand(a:path))
    endif
  endfunction " }}}

  function! s:source(begin, end) " {{{
    let lines = getline(a:begin, a:end)
    for line in lines
      execute line
    endfor
  endfunction " }}}

  function! s:preserve(command) " {{{
    " preparation: save last search and cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")
    " execute
    execute a:command
    " clean up: restore previous search history and cursor position
    let @/=_s
    call cursor(l, c)
  endfunction " }}}

  function! s:strip_trailing_whitespace() " {{{
    call s:preserve("%s/\\s\\+$//e")
  endfunction " }}}
" }}}

" base configuration {{{
  if has('autocmd')
    filetype plugin indent on
  endif
  if has('syntax') && !exists('g:syntax_on')
    syntax enable
  endif

  set complete-=i

  " whitespace
  set backspace=indent,eol,start
  set autoindent
  set expandtab
  set smarttab
  let &tabstop=s:settings.default_indent
  let &softtabstop=s:settings.default_indent
  let &shiftwidth=s:settings.default_indent
  set list

  set listchars=tab:▸\ ,trail:•,extends:❯,precedes:❮

  set shiftround
  set linebreak
  let &showbreak='↪ '

  set scrolloff=5
  set sidescroll=1
  set sidescrolloff=10
  set display+=lastline

  if &shell =~# 'fish$'
    set shell=/bin/bash
  endif

  set nrformats-=octal

  set ttimeout
  set timeoutlen=500
  set ttimeoutlen=50
  set viewoptions=folds,options,cursor,unix,slash
  set encoding=utf-8
  set hidden
  set autoread
  set tags=tags;/
  set showfulltag
  set modeline
  set modelines=5

  set incsearch
  set laststatus=2
  set ruler
  set showcmd
  set wildmenu

  " disable sounds
  set noerrorbells
  set novisualbell
  set t_vb=

  " searching
  set hlsearch
  set incsearch
  set ignorecase
  set smartcase

  if s:has_ag
    " use ag if available
    set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
    set grepformat=%f:%l:%c:%m
  elseif s:has_ack
    " fallback to ack if available
    set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
    set grepformat=%f:%l:%c:%m
  endif

  " vim file/folder management {{{
    " persistent undo
    if exists('+undofile')
      set undofile
      let &undodir = s:get_cache_dir('undo')
    endif

    " backups
    set backup
    let &backupdir = s:get_cache_dir('backup')

    " swap files
    let &directory = s:get_cache_dir('swap')
    set noswapfile

    call s:ensure_dir_exists(s:cache_dir)
    call s:ensure_dir_exists(&undodir)
    call s:ensure_dir_exists(&backupdir)
    call s:ensure_dir_exists(&directory)

  " }}}

  let mapleader = ","
  let g:mapleader = ","
" }}}

" ui configuration {{{
  set showmatch
  set matchtime=2
  set number
  set lazyredraw
  set laststatus=2
  set noshowmode
  set foldenable
  set foldmethod=syntax
  set foldlevelstart=99
  let g:xml_syntax_folding=1

  set cursorline
  autocmd WinLeave * setlocal nocursorline
  autocmd WinEnter * setlocal cursorline
  let &colorcolumn=s:settings.max_column
  if s:settings.enable_cursorcolumn
    set cursorcolumn
    autocmd WinLeave * setlocal nocursorcolumn
    autocmd WinEnter * setlocal cursorcolumn
  endif
" }}}

" vim-plug setup {{{
  call plug#begin(s:get_vim_dir('plugged'))
" }}}

" plugin/mapping configuration {{{
  if count(s:settings.plugin_groups, 'core') " {{{
    Plug 'bling/vim-airline' " {{{
      let g:airline_left_sep=''
      let g:airline_right_sep=''
      let g:airline#extensions#tabline#enabled = 1
      let g:airline#extensions#tabline#left_sep=' '
      let g:airline#extensions#tabline#right_sep=' '
      let g:airline#extensions#tabline#left_alt_sep='¦'
    " }}}
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'morhetz/gruvbox'

    if !s:is_nvim
      function! DotvimBuildVimproc(info)
        if a:info.status == 'installed' || a:info.status == 'updated' || a:info.force
          if s:is_mac
            !make -f make_mac.mak
          elseif s:is_unix
            !make -f make_unix.mak
          elseif s:is_cygwin
            !make -f make_cygwin.mak
          endif
        endif
      endfunction

      Plug 'Shougo/vimproc.vim', { 'do': function('DotvimBuildVimproc') }
    endif
  endif " }}}
  if count(s:settings.plugin_groups, 'go') " {{{
    Plug 'fatih/vim-go'
  endif " }}}
  if count(s:settings.plugin_groups, 'scm') " {{{
    Plug 'tpope/vim-fugitive' " {{{
      nnoremap <silent> <leader>gs :Gstatus<CR>
      nnoremap <silent> <leader>gd :Gdiff<CR>
      nnoremap <silent> <leader>gc :Gcommit<CR>
      nnoremap <silent> <leader>gb :Gblame<CR>
      nnoremap <silent> <leader>gl :Glog<CR>
      nnoremap <silent> <leader>gp :Git push<CR>
      nnoremap <silent> <leader>gw :Gwrite<CR>
      nnoremap <silent> <leader>gr :Gremove<CR>
    " }}}
    Plug 'gregsexton/gitv' " {{{
      nnoremap <silent> <leader>gv :Gitv<CR>
      nnoremap <silent> <leader>gV :Gitv!<CR>
    " }}}
  endif " }}}
  if count(s:settings.plugin_groups, 'navigation') " {{{
    Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } " {{{
      let NERDTreeShowHidden=0
      let NERDTreeQuitOnOpen=0
      let NERDTreeShowLineNumbers=1
      let NERDTreeChDirMode=0
      let NERDTreeShowBookmarks=1
      let NERDTreeIgnore=['\.git']

      nnoremap <F2> :NERDTreeToggle<CR>
      nnoremap <F3> :NERDTreeFind<CR>
    " }}}
    Plug 'majutsushi/tagbar' " {{{
      nnoremap <silent> <F8> :TagbarToggle<CR>
    " }}}
  endif " }}}
  if count(s:settings.plugin_groups, 'unite') " {{{
    Plug 'Shougo/unite.vim' " {{{
      let g:unite_data_directory=s:get_cache_dir('unite')
      let g:unite_enable_start_insert=1
      let g:unite_source_history_yank_enable=1
      let g:unite_source_rec_max_cache_files=5000
      let g:unite_prompt='» '

      if s:has_ag
        let g:unite_source_grep_command='ag'
        let g:unite_source_grep_default_opts='--nocolor --line-numbers --nogroup -S -C4'
        let g:unite_source_grep_recursive_opt=''
      elseif s:has_ack
        let g:unite_source_grep_command='ack'
        let g:unite_source_grep_default_opts='--no-heading --no-color -a -C4'
        let g:unite_source_grep_recursive_opt=''
      endif

      function! s:unite_settings()
        nmap <buffer> Q <plug>(unite_exit)
        nmap <buffer> <esc> <plug>(unite_exit)
        imap <buffer> <esc> <plug>(unite_exit)
      endfunction
      autocmd FileType unite call s:unite_settings()

      nmap <space> [unite]
      nnoremap [unite] <nop>

      if s:is_nvim
        " Use file_rec/neovim source
        nnoremap <silent> [unite]<space> :<C-u>Unite -toggle -auto-resize -buffer-name=mixed file_rec/neovim:! buffer file_mru bookmark<cr><c-u>
        nnoremap <silent> [unite]f :<C-u>Unite -toggle -auto-resize -buffer-name=files file_rec/neovim:!<cr><c-u>
      elseif s:is_windows
        " Don't use async at all
        nnoremap <silent> [unite]<space> :<C-u>Unite -toggle -auto-resize -buffer-name=mixed file_rec:! buffer file_mru bookmark<cr><c-u>
        nnoremap <silent> [unite]f :<C-u>Unite -toggle -auto-resize -buffer-name=files file_rec:!<cr><c-u>
      else
        " Use vimproc async
        nnoremap <silent> [unite]<space> :<C-u>Unite -toggle -auto-resize -buffer-name=mixed file_rec/async:! buffer file_mru bookmark<cr><c-u>
        nnoremap <silent> [unite]f :<C-u>Unite -toggle -auto-resize -buffer-name=files file_rec/async:!<cr><c-u>
      endif

      nnoremap <silent> [unite]e :<C-u>Unite -buffer-name=recent file_mru<cr>
      nnoremap <silent> [unite]y :<C-u>Unite -buffer-name=yanks history/yank<cr>
      nnoremap <silent> [unite]l :<C-u>Unite -auto-resize -buffer-name=line line<cr>
      nnoremap <silent> [unite]b :<C-u>Unite -auto-resize -buffer-name=buffers buffer<cr>
      nnoremap <silent> [unite]/ :<C-u>Unite -no-quit -buffer-name=search grep:.<cr>
      nnoremap <silent> [unite]m :<C-u>Unite -auto-resize -buffer-name=mappings mapping<cr>
      nnoremap <silent> [unite]s :<C-u>Unite -quick-match buffer<cr>
    " }}}
    Plug 'Shougo/neomru.vim'
    Plug 'ujihisa/unite-colorscheme' " {{{
      nnoremap <silent> [unite]c :<C-u>Unite -auto-resize -auto-preview -buffer-name=colorschemes colorscheme<cr>
    " }}}
  endif " }}}
  if count(s:settings.plugin_groups, 'autocomplete') " {{{
    Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --gocode-completer' } " {{{
      let g:ycm_complete_in_comments_and_strings=1
      let g:ycm_key_list_select_completion=['<C-n>', '<Down>']
      let g:ycm_key_list_previous_completion=['<C-p>', '<Up>']
      let g:ycm_filetype_blacklist={'unite': 1}
      nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR>
    " }}}
    Plug 'SirVer/ultisnips' " {{{
      let g:UltiSnipsExpandTrigger="<tab>"
      let g:UltiSnipsJumpForwardTrigger="<tab>"
      let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
      let g:UltiSnipsSnippetsDir=s:get_vim_dir('snippets')
    " }}}

  endif " }}}
  if count(s:settings.plugin_groups, 'misc') " {{{
    Plug 'scrooloose/syntastic' " {{{
      let g:syntastic_error_symbol = '✗'
      let g:syntastic_style_error_symbol = '✠'
      let g:syntastic_warning_symbol = '∆'
      let g:syntastic_style_warning_symbol = '≈'
    " }}}
    Plug 'zhaocai/GoldenView.vim', { 'on': '<Plug>ToggleGoldenViewAutoResize' } " {{{
      let g:goldenview__enable_default_mapping=0
      nmap <F4> <Plug>ToggleGoldenViewAutoResize
    " }}}
    Plug 'zah/nim.vim'
    Plug 'rodjek/vim-puppet'
  endif " }}}
" }}}

" mappings {{{
  " formatting shortcuts {{{
    nmap <leader>fef :call <sid>preserve("normal gg=G")<CR>
    nmap <leader>f$ :call <sid>strip_trailing_whitespace()<CR>
    vmap <leader>s :sort<cr>
  " }}}

  " eval vimscript by line or visual selection {{{
    nmap <silent> <leader>e :call <sid>source(line('.'), line('.'))<CR>
    vmap <silent> <leader>e :call <sid>source(line('v'), line('.'))<CR>
  " }}}

  " paste toggling {{{
    nnoremap <F6> :set invpaste paste?<CR>
    imap <F6> <C-O>:set invpaste paste?<CR>
    set pastetoggle=<F6>
  " }}}

  " sane regex {{{
    nnoremap / /\v
    vnoremap / /\v
    nnoremap ? ?\v
    vnoremap ? ?\v
    nnoremap :s/ :s/\v
  " }}}

  " folds {{{
    nnoremap zr zr:echo &foldlevel<cr>
    nnoremap zm zm:echo &foldlevel<cr>
    nnoremap zR zR:echo &foldlevel<cr>
    nnoremap zM zM:echo &foldlevel<cr>
  " }}}

  " screen line scroll {{{
    nnoremap <silent> j gj
    nnoremap <silent> k gk
    nnoremap <silent> gj j
    nnoremap <silent> gk k
  " }}}

  " auto center {{{
    nnoremap <silent> n nzz
    nnoremap <silent> N Nzz
    nnoremap <silent> * *zz
    nnoremap <silent> # #zz
    nnoremap <silent> g* g*zz
    nnoremap <silent> g# g#zz
    nnoremap <silent> <C-o> <C-o>zz
    nnoremap <silent> <C-i> <C-i>zz
  " }}}

  " reselect visual block after indent {{{
    vnoremap < <gv
    vnoremap > >gv
  " }}}

  " clear search highlighting
  noremap <silent> <leader><space> :noh<cr>:call clearmatches()<cr>
" }}}

" finish loading {{{
  call plug#end()
  exec 'colorscheme '.s:settings.colorscheme

" }}}
