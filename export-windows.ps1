# Copies the current Windows configuration into this repository, so changes made on Windows
# can be committed and then applied on the Mac with setup-mac.sh.
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

Copy-Item "$env:APPDATA\Code\User\settings.json" "$repo\vscode\settings.json" -Force
# Sorted, UTF-8 without BOM, LF line endings, so setup-mac.sh reads the IDs cleanly.
# Islet is left out on purpose: the setup scripts build it from its own repository.
$extensions = code --list-extensions 2>$null | Where-Object { $_ -and $_ -ne 'reapermaga.islet' } | Sort-Object
[IO.File]::WriteAllText("$repo\vscode\extensions.txt", (($extensions -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
Copy-Item "$env:USERPROFILE\.config\starship.toml" "$repo\starship\starship.toml" -Force
Copy-Item "$env:APPDATA\nushell\config.nu" "$repo\nushell\config.nu" -Force

Write-Host "Exported. Review with 'git diff', then commit and push."
