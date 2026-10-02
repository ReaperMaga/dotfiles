# dotfiles

My editor and terminal setup, shared between Windows and macOS.

- **VS Code:** Air dark theme with Islands-style floating panels, Rider syntax colours, JetBrains Mono
  and Inter, restyled Source Control, plus my extensions.
- **Terminal:** Nushell with a Starship prompt of rounded "pills" (folder, branch, language,
  duration, exit code).
- **Islet:** my GitHub issues and pull requests panel for VS Code, built from
  [ReaperMaga/islet](https://github.com/ReaperMaga/islet).

## Set up a Mac

Needs [Homebrew](https://brew.sh) and VS Code.

```bash
git clone https://github.com/ReaperMaga/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup-mac.sh
```

The script installs the fonts (JetBrains Mono, JetBrains Mono Nerd Font, Inter), Starship,
Nushell and Node, installs the VS Code extensions, copies the settings (backing up anything it
replaces), builds and installs Islet, and configures Starship for Nushell. It is safe to run again.

Afterwards:

1. In VS Code run **Custom UI Style: Reload** (Cmd+Shift+P) once.
2. Set your terminal app's font to **JetBrainsMono Nerd Font** and its shell to `nu`.

## Update from Windows

After changing something on Windows:

```powershell
.\export-windows.ps1
git diff
git commit -am "chore: update settings"
git push
```

Then on the Mac: `git pull && ./setup-mac.sh`.

## Layout

```
vscode/settings.json     VS Code user settings (Windows and macOS terminal profiles included)
vscode/extensions.txt    Marketplace extensions to install
starship/starship.toml   prompt design
nushell/config.nu        Nushell settings
setup-mac.sh             applies everything on a Mac
export-windows.ps1       refreshes this repo from the Windows machine
```
