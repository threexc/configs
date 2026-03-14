" Make sure Python virtualenvs don't throw a warning when starting vim.
if exists('$VIRTUAL_ENV')
    let &pythonthreedll = system("find /usr/lib64 -name 'libpython3.*.so.1.0' | tail -1 | tr -d '\n'")
    python3 << EOF
import sys
import sysconfig
sys.path.insert(0, sysconfig.get_path('purelib', vars={'base': '/usr', 'platbase': '/usr'}))
EOF
endif

" Uncomment this instead if using neovim:
" if exists('$VIRTUAL_ENV')
"    let g:python3_host_prog = '/usr/bin/python3'
" endif

execute pathogen#infect()
syntax on
colorscheme desert

" Use filetype detection and file-based automatic indenting
if has('filetype')
    filetype plugin indent on
endif

set pastetoggle=<F2>    " hotkey for paste mode to avoid extra indentation
set updatetime=100      " reduce time between updates from 4000ms to 100ms
set textwidth=80        " wrap width
set autoindent          " automatically indent
set visualbell          " don't beep
set mouse=              " disable mouse

if has("autocmd")
    " Use actual tab chars in Makefiles
    autocmd FileType make setlocal tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
    autocmd FileType c    setlocal tabstop=8 shiftwidth=8 softtabstop=8 noexpandtab
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
    autocmd FileType rust   setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
    autocmd FileType yaml   setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    autocmd BufNewFile,BufRead *.v,*.vs setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
endif

let g:airline_powerline_fonts = 1
