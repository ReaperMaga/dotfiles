# Sets up a Windows PC with the same VS Code look, terminal prompt and shell.
# Safe to run again: steps that are already done are skipped, replaced files are backed up first.
# Run from PowerShell:  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
param(
  # Where Islet (the GitHub panel extension) is cloned and built.
  [string]$IsletDir = "$HOME\Projects\islet"
)

# Not 'Stop': Windows PowerShell would treat any stderr line from code/git/npm as fatal.
# External programs are checked by exit code; cmdlets that must succeed use -ErrorAction Stop.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # makes Invoke-WebRequest much faster in Windows PowerShell
$Dotfiles = $PSScriptRoot
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say([string]$Text)  { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Warn([string]$Text) { Write-Host "!! $Text" -ForegroundColor Yellow }

function Update-SessionPath {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Backup-AndCopy([string]$Source, [string]$Dest) {
  New-Item -ItemType Directory -Force (Split-Path $Dest) | Out-Null
  if (Test-Path $Dest) {
    if ((Get-FileHash $Source).Hash -eq (Get-FileHash $Dest).Hash) { Write-Host "   unchanged $Dest"; return }
    Copy-Item $Dest "$Dest.backup-$Stamp" -ErrorAction Stop
    Write-Host "   backed up $Dest"
  }
  Copy-Item $Source $Dest -Force -ErrorAction Stop
  Write-Host "   wrote $Dest"
}

# ---------------------------------------------------------------- apps
Say 'Installing apps with winget (skipping ones already installed)'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Warn 'winget is missing. Install "App Installer" from the Microsoft Store, then run this script again.'
  exit 1
}
$apps = @(
  @{ Id = 'Microsoft.VisualStudioCode'; Cmd = 'code' },
  @{ Id = 'Git.Git';                    Cmd = 'git' },
  @{ Id = 'OpenJS.NodeJS.LTS';          Cmd = 'node' },
  @{ Id = 'Starship.Starship';          Cmd = 'starship' },
  @{ Id = 'Nushell.Nushell';            Cmd = 'nu' }
)
foreach ($app in $apps) {
  if (Get-Command $app.Cmd -ErrorAction SilentlyContinue) { Write-Host "   $($app.Id) already installed"; continue }
  winget install --id $app.Id -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
  Update-SessionPath
  Write-Host "   installed $($app.Id)"
}
Update-SessionPath
foreach ($app in $apps) {
  if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
    Warn "$($app.Cmd) is still not on PATH. Open a new PowerShell window and run this script again."
    exit 1
  }
}

# ---------------------------------------------------------------- fonts (per user, no admin needed)
Say 'Installing fonts'
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$fontReg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force $fontDir | Out-Null

function Install-FontRelease([string]$Name, [string]$Repo, [string]$AssetPattern, [string]$FilePattern, [string]$Exclude) {
  if (Get-ChildItem $fontDir -Filter $FilePattern -ErrorAction SilentlyContinue) { Write-Host "   $Name already installed"; return }
  $tmp = Join-Path $env:TEMP "font-$([guid]::NewGuid())"
  New-Item -ItemType Directory $tmp | Out-Null
  $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -ErrorAction Stop
  $asset = $release.assets | Where-Object { $_.name -like $AssetPattern } | Select-Object -First 1
  Invoke-WebRequest $asset.browser_download_url -OutFile "$tmp\font.zip" -UseBasicParsing -ErrorAction Stop
  Expand-Archive "$tmp\font.zip" "$tmp\x" -Force -ErrorAction Stop
  $files = Get-ChildItem "$tmp\x" -Recurse -Filter $FilePattern | Where-Object { -not $Exclude -or $_.FullName -notmatch $Exclude }
  foreach ($f in $files) {
    Copy-Item $f.FullName $fontDir -Force
    New-ItemProperty $fontReg -Name "$($f.BaseName) (TrueType)" -Value "$fontDir\$($f.Name)" -PropertyType String -Force | Out-Null
  }
  Remove-Item $tmp -Recurse -Force
  Write-Host "   installed $Name $($release.tag_name) ($($files.Count) files)"
}
Install-FontRelease 'JetBrains Mono'           'JetBrains/JetBrainsMono'   '*.zip'             'JetBrainsMono-*.ttf'         '\\variable\\'
Install-FontRelease 'JetBrains Mono Nerd Font' 'ryanoasis/nerd-fonts'      'JetBrainsMono.zip' 'JetBrainsMonoNerdFont-*.ttf' ''
Install-FontRelease 'Inter'                    'rsms/inter'                'Inter-*.zip'       'Inter*.ttf'                  'Display|\\web\\'

# ---------------------------------------------------------------- VS Code
Say 'Installing VS Code extensions'
Get-Content "$Dotfiles\vscode\extensions.txt" | Where-Object { $_.Trim() } | ForEach-Object {
  code --install-extension $_.Trim() --force 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "   $($_.Trim())" } else { Warn "could not install $($_.Trim())" }
}

Say 'Applying VS Code settings'
Backup-AndCopy "$Dotfiles\vscode\settings.json" "$env:APPDATA\Code\User\settings.json"

# ---------------------------------------------------------------- Islet (not on the Marketplace)
Say 'Building and installing Islet'
if (Test-Path "$IsletDir\.git") {
  git -C $IsletDir pull --ff-only 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Warn "could not update $IsletDir (local changes?), building what is there" }
} else {
  New-Item -ItemType Directory -Force (Split-Path $IsletDir) | Out-Null
  git clone -q https://github.com/ReaperMaga/islet.git $IsletDir 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'git clone of Islet failed' }
}
Push-Location $IsletDir
try {
  npm install --silent 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'npm install failed' }
  npm run package --silent 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'npm run package failed' }
  $vsix = Get-ChildItem -Filter 'islet-*.vsix' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  code --install-extension $vsix.FullName --force 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'installing the Islet package failed' }
  Write-Host "   installed $($vsix.Name) from $IsletDir"
} finally {
  Pop-Location
}

# ---------------------------------------------------------------- Starship + Nushell
Say 'Configuring Starship and Nushell'
Backup-AndCopy "$Dotfiles\starship\starship.toml" "$HOME\.config\starship.toml"

$nuDirs = (nu -n -c 'print $nu.default-config-dir; print ($nu.user-autoload-dirs | first)') -split "`r?`n" | Where-Object { $_ }
$nuConfigDir = $nuDirs[0]
$nuAutoload = $nuDirs[1]
Backup-AndCopy "$Dotfiles\nushell\config.nu" "$nuConfigDir\config.nu"

New-Item -ItemType Directory -Force $nuAutoload | Out-Null
# Generated on this machine, so it contains this PC's starship path.
$init = (starship init nu) -join "`n"
[IO.File]::WriteAllText("$nuAutoload\starship.nu", $init + "`n", (New-Object Text.UTF8Encoding($false)))
Write-Host "   wrote $nuAutoload\starship.nu"

# ---------------------------------------------------------------- Windows Terminal
Say 'Configuring Windows Terminal (Nerd Font, Nushell as default)'
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (-not (Test-Path $wtSettings)) {
  Warn 'Windows Terminal settings not found. Open Windows Terminal once, then run this script again for this step.'
} else {
  $raw = Get-Content $wtSettings -Raw -Encoding UTF8
  # Windows Terminal allows // comments; strip them so Windows PowerShell can parse the file.
  $json = ([regex]::Replace($raw, '(?m)^\s*//.*$', '')) | ConvertFrom-Json -ErrorAction Stop
  $nuPath = (Get-Command nu).Source

  # Prefer the profile Windows Terminal detects for Nushell itself, then any profile that starts nu.exe.
  $nuProfile = @($json.profiles.list | Where-Object { $_.source -eq 'nu' }) + @($json.profiles.list | Where-Object { $_.commandline -and $_.commandline -like '*nu.exe*' }) | Select-Object -First 1
  $changed = $false
  if (-not $nuProfile) {
    $nuProfile = [pscustomobject]@{
      guid = "{$([guid]::NewGuid())}"; name = 'Nushell'; commandline = $nuPath
      startingDirectory = '%USERPROFILE%'; hidden = $false
    }
    $json.profiles.list = @($json.profiles.list) + $nuProfile
    $changed = $true
  }

  foreach ($p in @($json.profiles.list | Where-Object { $_.source -eq 'nu' -or ($_.commandline -and $_.commandline -like '*nu.exe*') })) {
    if ($p.PSObject.Properties['font'] -and $p.font.face -eq 'JetBrainsMono Nerd Font') { continue }
    $font = [pscustomobject]@{ face = 'JetBrainsMono Nerd Font'; size = 12 }
    if ($p.PSObject.Properties['font']) { $p.font = $font } else { $p | Add-Member font $font }
    $changed = $true
  }
  if ($json.defaultProfile -ne $nuProfile.guid) { $json.defaultProfile = $nuProfile.guid; $changed = $true }

  if ($changed) {
    Copy-Item $wtSettings "$wtSettings.backup-$Stamp" -ErrorAction Stop
    [IO.File]::WriteAllText($wtSettings, ($json | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding($false)))
    Write-Host "   default profile: $($nuProfile.name), font: JetBrainsMono Nerd Font (backup saved)"
  } else {
    Write-Host "   already set up"
  }
}

# ---------------------------------------------------------------- done
Say 'Done. One manual step left:'
Write-Host '   Open VS Code, press Ctrl+Shift+P and run "Custom UI Style: Reload", then let it restart.'
Write-Host '   (Turns on the Islands panels and the Inter UI font. If VS Code then says the installation'
Write-Host '   is "corrupt", click the gear on that message and choose "Don''t show again".)'
Write-Host '   Restart Windows Terminal to see the new prompt.'
