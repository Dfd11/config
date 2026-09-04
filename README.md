# dotfiles

This repo *is* `~/.config`. Everything not part of the setup is ignored by
`.gitignore` (whitelist-style — add new things there explicitly).

## New machine

```sh
git clone <this-repo> ~/.config   # or into a temp dir and rsync over ~/.config
~/.config/sixtailfox/setup.sh
```

The script is idempotent — re-run it any time.

## Layout

| path              | what                                                    |
|-------------------|---------------------------------------------------------|
| `nvim/`           | LazyVim config (plugins in `nvim/lua/plugins/`)          |
| `alacritty/`      | terminal config + github-dark themes                     |
| `sixtailfox/`     | shell setup: `setup.sh` installer, `setup_shared` (bash+zsh), `setup_zshrc`, `setup_bashrc` |
| `home/`           | dotfiles that must live in `$HOME`; symlinked by the installer |
| `zsh_functions/`  | zsh completion functions                                 |

## Not in the repo

`~/.company_config` and `~/.bashrc.secrets` are machine-local secrets. The
rc files source them only if present.
