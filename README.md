# dotnvim

A configuration for [neovim][neovim], although it should work fine in [vim][vim].
Heavily inspired by [bling's dotvim][blingdotvim].

## installation

1.  clone this repository into your `~/.nvim` directory
1.  `mv ~/.vimrc ~/.vimrc.backup`
1.  create the following shim and save it as `~/.vimrc`:

```
let g:dotvim_settings = {}
let g:dotvim_settings.version = 2
let g:dotvim_settings.root_dir = '~/.nvimrc'

source ~/.nvim/vimrc
```

[neovim]: https://github.com/neovim/neovim
[vim]: http://www.vim.org
[blingdotvim]: https://github.com/bling/dotvim
