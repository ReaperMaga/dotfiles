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

## Set up Windows

Needs [winget](https://learn.microsoft.com/windows/package-manager/winget/) (preinstalled on
Windows 10/11 as "App Installer") and [Windows Terminal](https://aka.ms/terminal).

```powershell
git clone https://github.com/ReaperMaga/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

On a brand-new PC without Git, run `winget install Git.Git` first and open a new PowerShell window.

The script installs VS Code, Git, Node, Starship and Nushell with winget (skipping ones already
there), the fonts for your user (no admin needed), the VS Code extensions and settings, builds and
installs Islet (to `$HOME\Projects\islet`, change with `-IsletDir`), configures Starship for
Nushell, and sets Windows Terminal's Nushell profile as default with the Nerd Font. Replaced files
are backed up first, and it is safe to run again.

Afterwards, run **Custom UI Style: Reload** in VS Code (Ctrl+Shift+P) once and restart Windows
Terminal.

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
setup-windows.ps1        applies everything on Windows
export-windows.ps1       refreshes this repo from the Windows machine
```
