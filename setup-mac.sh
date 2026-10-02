#!/usr/bin/env bash
# Sets up a Mac with the same VS Code look, terminal prompt and shell as the Windows machine.
# Safe to run again: existing files are backed up with a timestamp before being replaced.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
ISLET_DIR="${ISLET_DIR:-$HOME/Projects/islet}"

say()  { printf '\n\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

backup_and_copy() { # src dest
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && ! cmp -s "$1" "$2"; then
    cp "$2" "$2.backup-$STAMP"
    echo "   backed up $2"
  fi
  cp "$1" "$2"
  echo "   wrote $2"
}

# ---------------------------------------------------------------- Homebrew
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew is not installed. Install it from https://brew.sh, then run this script again."
  exit 1
fi
BREW_PREFIX="$(brew --prefix)"

say "Installing fonts, Starship, Nushell and Node"
brew install --cask font-jetbrains-mono font-jetbrains-mono-nerd-font font-inter || true
brew install starship nushell node git

# ---------------------------------------------------------------- VS Code
CODE="code"
if ! command -v code >/dev/null 2>&1; then
  CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [ ! -x "$CODE" ]; then
    warn "VS Code not found. Install it (brew install --cask visual-studio-code), then run this script again."
    exit 1
  fi
fi

say "Installing VS Code extensions"
while IFS= read -r ext; do
  [ -n "$ext" ] && "$CODE" --install-extension "$ext" --force >/dev/null && echo "   $ext"
done < "$DOTFILES/vscode/extensions.txt"

say "Applying VS Code settings"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
TMP_SETTINGS="$(mktemp)"
# Point the Nushell terminal profile at this Mac's Homebrew (Apple silicon: /opt/homebrew, Intel: /usr/local).
sed "s#/opt/homebrew/bin/nu#$BREW_PREFIX/bin/nu#" "$DOTFILES/vscode/settings.json" > "$TMP_SETTINGS"
backup_and_copy "$TMP_SETTINGS" "$VSCODE_USER/settings.json"
rm -f "$TMP_SETTINGS"

# ---------------------------------------------------------------- Islet (not on the Marketplace)
say "Building and installing Islet"
if [ -d "$ISLET_DIR/.git" ]; then
  git -C "$ISLET_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$ISLET_DIR")"
  git clone https://github.com/ReaperMaga/islet.git "$ISLET_DIR"
fi
(
  cd "$ISLET_DIR"
  npm install --silent
  npm run package --silent
  "$CODE" --install-extension "$(ls -t islet-*.vsix | head -1)" --force >/dev/null
)
echo "   installed from $ISLET_DIR"

# ---------------------------------------------------------------- Starship + Nushell
say "Configuring Starship and Nushell"
backup_and_copy "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"

NU_CONFIG_DIR="$(nu -n -c '$nu.default-config-dir')"
backup_and_copy "$DOTFILES/nushell/config.nu" "$NU_CONFIG_DIR/config.nu"

NU_AUTOLOAD="$(nu -n -c '$nu.user-autoload-dirs | first')"
mkdir -p "$NU_AUTOLOAD"
# Generated on this machine, so it contains this Mac's starship path.
starship init nu > "$NU_AUTOLOAD/starship.nu"
echo "   wrote $NU_AUTOLOAD/starship.nu"

# ---------------------------------------------------------------- done
say "Done. Two manual steps left:"
cat <<'EOF'
   1. Open VS Code, press Cmd+Shift+P and run "Custom UI Style: Reload", then let it restart.
      (This turns on the Islands panels and the Inter UI font. VS Code may then say the
      installation is "corrupt": click the gear on that message and choose "Don't show again".)
   2. In your terminal app, set the font to "JetBrainsMono Nerd Font" and the shell to Nushell
      (e.g. Ghostty: font-family = JetBrainsMono Nerd Font, command = nu). The prompt pills need
      that font.
EOF
