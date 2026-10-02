# Copies the current Windows configuration into this repository, so changes made on Windows
# can be committed and then applied on the Mac with setup-mac.sh.
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

Copy-Item "$env:APPDATA\Code\User\settings.json" "$repo\vscode\settings.json" -Force
code --list-extensions | Where-Object { $_ -and $_ -ne 'reapermaga.islet' } |
  Set-Content "$repo\vscode\extensions.txt" -Encoding utf8
Copy-Item "$env:USERPROFILE\.config\starship.toml" "$repo\starship\starship.toml" -Force
Copy-Item "$env:APPDATA\nushell\config.nu" "$repo\nushell\config.nu" -Force

Write-Host "Exported. Review with 'git diff', then commit and push."
