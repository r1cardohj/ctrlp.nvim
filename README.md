# ctrlp.nvim

> A fuzzy file finder for Neovim, written in pure Lua. Built because existing finders were either too heavy or didn't feel right.


![ctrlp.nvim screenshot](assets/screenshot.png)


## Why

- Zero external dependencies — no fzf, no fd, just Lua and Neovim APIs
- Small codebase, easy to hack on
- Float window with real-time filtering, inspired by VS Code's Command Palette

## Install

```lua
-- lazy.nvim
{
  "r1cardohj/ctrlp.nvim",
  config = function()
    require("ctrlp").setup()
  end
}
```

For local development, symlink it directly:

```bash
cd ~/.config/nvim/lua && ln -s /path/to/ctrlp.nvim ./ctrlp.nvim
```

## Usage

| Key | Action |
|---|---|
| `<C-p>` or `:CtrlP` | Open the finder |
| Type | Filter files in real time |
| `<CR>` | Open selected file |
| `<C-n>` / `<C-p>` | Navigate down / up |
| `<Down>` / `<Up>` | Same as above |
| `<Esc>` / `<C-c>` | Close |

## Setup

```lua
require("ctrlp").setup({
  max_files = 10000,
  ignore_patterns = {
    "^%.git/",
    "^node_modules/",
    "^target/",
    "^dist/",
    "^build/",
  },
})
```

## Develop

```bash
# Run tests
make test

# Clean test dependencies
make clean
```

## Roadmap

- [x] Fuzzy matching with scoring
- [x] Float window UI
- [x] Selection highlight
- [x] Basic test coverage
- [ ] MRU (most recently used) file priority
- [ ] VS Code-style mode switching (`> command`, `% buffer`, etc.)
- [ ] Devicon support
- [ ] Async scanning for large directories

## License

MIT — do whatever you want.
