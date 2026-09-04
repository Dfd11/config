#!/usr/bin/env bash
# Bootstrap a fresh machine from this repo (which lives at ~/.config).
#
#   git clone <repo> ~/.config
#   ~/.config/sixtailfox/setup.sh            # everything
#   ~/.config/sixtailfox/setup.sh shell nvim # only some stages
#
# Idempotent: safe to re-run. Skips anything already installed.
set -euo pipefail

CONFIG="$HOME/.config"
NVIM_VERSION="v0.11.2"
GO_VERSION="1.26.4"
LAZYGIT_VERSION="0.59.0"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Run stage $1 only if it was requested (no args = all stages).
STAGES=("$@")
want() {
  [ ${#STAGES[@]} -eq 0 ] && return 0
  local s; for s in "${STAGES[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

clone() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    info "update $(basename "$dest")"
    git -C "$dest" pull --ff-only --quiet || warn "could not update $dest"
  else
    info "clone $(basename "$dest")"
    git clone --depth 1 --quiet "$url" "$dest"
  fi
}

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then return; fi
  if [ -e "$dest" ]; then
    warn "backing up $dest -> $dest.backup"
    mv "$dest" "$dest.backup"
  fi
  ln -s "$src" "$dest"
  info "link $dest"
}

# ==============================================================================
# apt - base packages
# ==============================================================================
if want apt; then
info "installing apt packages (sudo)"
sudo apt-get update -qq
sudo apt-get install -y \
  build-essential cmake pkg-config curl wget git unzip \
  zsh tmux \
  ripgrep fd-find fzf jq \
  xclip wl-clipboard \
  python3 python3-pip python3-venv \
  nodejs npm \
  luarocks \
  fontconfig \
  libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev

# Ubuntu ships fd as fdfind; LazyVim expects `fd`.
mkdir -p "$HOME/.local/bin"
if ! have fd && have fdfind; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
fi

# ==============================================================================
# nvim - apt's is too old for LazyVim, use the upstream tarball
# ==============================================================================
if want nvim; then
if [ ! -x /opt/nvim-linux-x86_64/bin/nvim ]; then
  info "installing neovim $NVIM_VERSION to /opt"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-linux-x86_64.tar.gz"
  sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
  rm -rf "$tmp"
fi
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"

# tree-sitter CLI (npm package; nvim-treesitter needs it to compile parsers)
if ! have tree-sitter; then
  info "installing tree-sitter-cli"
  sudo npm install -g tree-sitter-cli
fi
fi

# ==============================================================================
# lang - Go and Rust toolchains
# ==============================================================================
if want lang; then
if [ ! -x /usr/local/go/bin/go ]; then
  info "installing go $GO_VERSION to /usr/local"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/go.tar.gz" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$tmp/go.tar.gz"
  rm -rf "$tmp"
fi
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

info "installing go dev tools"
for pkg in \
  golang.org/x/tools/gopls@latest \
  golang.org/x/tools/cmd/goimports@latest \
  github.com/go-delve/delve/cmd/dlv@latest \
  github.com/josharian/impl@latest \
  github.com/haya14busa/goplay/cmd/goplay@latest
do
  go install "$pkg"
done

if ! have rustup; then
  info "installing rustup"
  curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"
fi

# ==============================================================================
# cli - lazygit, gh, docker, gcloud
# ==============================================================================
if want cli; then
if ! have lazygit; then
  info "installing lazygit $LAZYGIT_VERSION"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -C "$tmp" -xzf "$tmp/lazygit.tar.gz" lazygit
  sudo install "$tmp/lazygit" /usr/local/bin/
  rm -rf "$tmp"
fi

if ! have gh; then
  info "installing github cli"
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -qq && sudo apt-get install -y gh
fi

if ! have docker; then
  info "installing docker"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  warn "log out and back in for docker group membership to apply"
fi

if ! have gcloud; then
  info "installing google cloud sdk"
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  sudo apt-get update -qq && sudo apt-get install -y google-cloud-cli
fi
fi

# ==============================================================================
# term - alacritty (built from git master; the config in this repo targets it)
# ==============================================================================
if want term; then
if ! have alacritty; then
  info "building alacritty from source (slow)"
  export PATH="$HOME/.cargo/bin:$PATH"
  cargo install --git https://github.com/alacritty/alacritty.git --locked alacritty
  sudo install "$HOME/.cargo/bin/alacritty" /usr/local/bin/
fi
fi

# ==============================================================================
# shell - zsh plugins, prompt, fzf, tmux plugin manager, symlinks
# ==============================================================================
if want shell; then
clone https://github.com/romkatv/powerlevel10k.git              "$HOME/powerlevel10k"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git  "$HOME/.zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-autosuggestions.git      "$CONFIG/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-completions.git          "$CONFIG/zsh-completions"
clone https://github.com/Aloxaf/fzf-tab.git                     "$CONFIG/fzf-tab"
clone https://github.com/tmux-plugins/tpm.git                   "$HOME/.tmux/plugins/tpm"

# fzf's own checkout (setup_shared puts ~/.fzf/bin on PATH)
if [ ! -d "$HOME/.fzf" ]; then
  clone https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
fi

link "$CONFIG/home/zshrc"     "$HOME/.zshrc"
link "$CONFIG/home/bashrc"    "$HOME/.bashrc"
link "$CONFIG/home/p10k.zsh"  "$HOME/.p10k.zsh"
link "$CONFIG/home/tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.local/share/fonts/MesloLGS" ]; then
  info "installing MesloLGS Nerd Font"
  mkdir -p "$HOME/.local/share/fonts/MesloLGS"
  base="https://github.com/romkatv/powerlevel10k-media/raw/master"
  for f in "MesloLGS%20NF%20Regular.ttf" "MesloLGS%20NF%20Bold.ttf" \
           "MesloLGS%20NF%20Italic.ttf" "MesloLGS%20NF%20Bold%20Italic.ttf"; do
    curl -fsSL -o "$HOME/.local/share/fonts/MesloLGS/${f//%20/ }" "$base/$f"
  done
  fc-cache -f >/dev/null
fi

info "installing tmux plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "tpm install reported errors"

if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  info "setting zsh as the default shell"
  chsh -s "$(command -v zsh)" || warn "chsh failed - run it manually"
fi
fi

# ==============================================================================
# plugins - LazyVim plugins + the LSPs/formatters installed via Mason
# ==============================================================================
if want plugins; then
export PATH="/opt/nvim-linux-x86_64/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"

info "syncing LazyVim plugins (this takes a minute)"
nvim --headless "+Lazy! sync" +qa || warn "lazy sync reported errors"

# lazyvim.json has no extras enabled, so these were installed by hand and
# will NOT come back on their own.
info "installing Mason packages"
nvim --headless \
  "+MasonInstall gopls goimports gofumpt golangci-lint lua-language-server stylua shfmt" \
  +qa || warn "mason install reported errors"
fi

cat <<'DONE'

Done. Remaining manual bits:
  * Log out / back in (default shell + docker group).
  * Set the terminal font to "MesloLGS NF".
  * gh auth login   /   gcloud auth login
  * Machine-local secrets are NOT in this repo - create if you need them:
      ~/.company_config
      ~/.bashrc.secrets

Not scripted (licensed / machine-specific): MATLAB, Wolfram, CUDA, NVIDIA
drivers, Foxglove, Obsidian, CrowdStrike, cursor-agent, claude.
DONE
