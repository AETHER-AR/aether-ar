# AETHER AR -- the release installer ("Install AETHER AR.cmd" runs it).
#
# The package holds only the mod: its changes to BT3-Recomp as one patch (mod\aether-ar.patch -- the mod's complete
# source, GPL-3.0), the BT3-Recomp version it is made for (mod\BASE), and these scripts. Nothing of the game. This
#   1. asks for your own Budokai Tenkaichi 3 (USA) ISO and an install folder (default C:\AETHER-AR),
#   2. fetches BT3-Recomp from GitHub at exactly that version, without its history (git; installed with winget if it
#      is missing),
#   3. puts the mod's changes on it,
#   4. builds the game from your ISO on this PC (ar\install.ps1: Python, compiler, recompilation; 30-60 min),
#   5. puts "AETHER AR" on the desktop and in the Start menu, adds it to Settings > Apps (Uninstall) and opens the
#      launcher window.
# Run on the same folder again to update to a newer package: the memory card (games\bt3\savedata) and the settings
# (ar\config.json) are not part of the project and stay.
#
#   install-aether-ar.ps1 [-Iso <iso>] [-Dir <folder>] [-Yes] [-NoShortcuts] [-NoLaunch] [-NoTranscript]
# (setup-gui.ps1, the Setup window "Install AETHER AR.cmd" opens, runs this with -Iso -Dir -Yes -NoLaunch -NoTranscript
# and reads its output: the "[step] <id>" lines move its progress list, a "FAILED:" line is shown as the reason)
param([string]$Iso, [string]$Dir, [switch]$Yes, [switch]$NoShortcuts, [switch]$NoLaunch, [switch]$NoTranscript)
$ErrorActionPreference = 'Stop'
$pkg = Split-Path -Parent $PSScriptRoot
function Say($m) { Write-Host "[AETHER AR] $m" -ForegroundColor Cyan }
function Step($id) { if ($env:AETHER_SETUP_STEPS -eq '1') { Write-Host "[step] $id" } }   # (only for the Setup window: check, git, fetch, mod, tools -- then ar\install.ps1's)
function Ask($q) { if ($Yes) { return $true }; return (Read-Host "$q [y/N]") -match '^(y|j)' }
# a tool this installer put on the PC (Git): the uninstaller (ar\uninstall.ps1) names it at the end -- it stays, other
# programs may use it. (ar\shortcuts.ps1 Add-AetherInstalledTool does the same for the build tools; this runs before
# that file is fetched.) Never fails the install.
function Note-Tool([string]$id) {
    try {
        $k = 'HKCU:\Software\AETHER-AR'; if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
        $have = @(); try { $have = @((Get-ItemProperty -LiteralPath $k -Name InstalledTools -ErrorAction Stop).InstalledTools | Where-Object { $_ }) } catch { }
        if ($have -notcontains $id) { New-ItemProperty -LiteralPath $k -Name InstalledTools -PropertyType MultiString -Value ([string[]]($have + $id)) -Force | Out-Null }
    } catch { }
}
$log = Join-Path $pkg 'install-log.txt'
# one installer at a time: a second double-click (the ISO window had opened behind the console, 31.10.) started a
# second install into the same folder -- and its transcript overwrote the first one's log. Checked before the log.
$installLock = New-Object System.Threading.Mutex($false, 'Local\AetherAR-install')
$ownsLock = $false; try { $ownsLock = $installLock.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $ownsLock = $true }
if (-not $ownsLock) { Write-Host "[AETHER AR] The installer is already running in another window -- finish it there (or close that window), then start this again." -ForegroundColor Yellow; exit 3 }
# (-LiteralPath for the package's own files: unpacked to a folder with [ ] in its name they were taken as wildcards)
# (-NoTranscript: the Setup window writes this log itself, from the output -- a transcript misses what native
# programs print, and two writers would clash)
if (-not $NoTranscript) { try { Start-Transcript -LiteralPath $log -Force | Out-Null } catch { } }

try {
    $base = @{}
    $basePath = Join-Path $pkg 'mod\BASE'
    if (-not (Test-Path -LiteralPath $basePath)) { throw "mod\BASE is missing -- the package is incomplete; download it again" }
    Get-Content -LiteralPath $basePath | ForEach-Object { if ($_ -match '^\s*(\w+)\s*=\s*(\S+)\s*$') { $base[$matches[1]] = $matches[2] } }
    foreach ($k in 'repo', 'commit', 'version') { if (-not $base[$k]) { throw "mod\BASE has no '$k' -- download the package again" } }
    $patch = Join-Path $pkg 'mod\aether-ar.patch'
    if (-not (Test-Path -LiteralPath $patch)) { throw "mod\aether-ar.patch is missing -- download the package again" }
    $checkIso = Join-Path $PSScriptRoot 'check-iso.ps1'
    if (-not (Test-Path -LiteralPath $checkIso)) { throw "setup\check-iso.ps1 is missing -- the package is incomplete; download it again" }
    try { $Host.UI.RawUI.WindowTitle = "AETHER AR $($base.version) -- install" } catch { }
    Say "AETHER AR $($base.version) -- unofficial bring-your-own-disc mixed-reality mod for Budokai Tenkaichi 3 (Meta Quest, Link / Air Link)"

    # 1. The ISO and the folder (asked first: the rest runs on its own)
    if (-not $Iso) {
        # said first, and the window in front of everything: it opened behind the console, and "open a folder?" was all
        # the player saw (31.10.)
        Say "Step 1: choose your Budokai Tenkaichi 3 USA disc image (the .iso file) in the window that opens now."
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = 'AETHER AR: choose your Budokai Tenkaichi 3 USA disc image (.iso)'
        $dlg.Filter = 'PS2 disc image (*.iso)|*.iso|All files (*.*)|*.*'
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        if (Test-Path -LiteralPath $downloads) { $dlg.InitialDirectory = $downloads }
        $front = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
        try { $answer = $dlg.ShowDialog($front) } finally { $front.Dispose() }
        if ($answer -ne 'OK') { throw "no ISO chosen -- start the installer again and choose your Budokai Tenkaichi 3 USA .iso file" }
        $Iso = $dlg.FileName
    }
    # (-LiteralPath: [ ] in the file name are no wildcards; ProviderPath: a \\NAS\ path tar can open -- release audit 31.10.)
    if (-not (Test-Path -LiteralPath $Iso -PathType Leaf)) { throw "ISO not found: $Iso" }
    $Iso = (Resolve-Path -LiteralPath $Iso).ProviderPath
    # the disc checked now, before the folder, git and the build: in ar\install.ps1 alone a wrong disc was found only
    # after git, the download and the patch (release audit 31.10.)
    Step 'check'
    & $checkIso -Iso $Iso -Work (Join-Path $pkg 'iso-check')
    Say "ISO: $Iso (Budokai Tenkaichi 3 USA, SLUS-21678 -- checked)"
    if (-not $Dir) {
        $default = 'C:\AETHER-AR'
        if ($Yes) { $Dir = $default }
        else { $in = Read-Host "Install folder (Enter = $default)"; $Dir = $(if ($in.Trim()) { $in.Trim().Trim('"') } else { $default }) }
    }
    $Dir = [IO.Path]::GetFullPath($Dir)
    # no spaces (the build tools are only proven without), no [ ] (PowerShell reads them as wildcards: the scripts that
    # run from this folder would not find their own files -- 31.10.), and a short path (Windows' 260-character limit)
    if ($Dir -match '[\s\[\]]') { throw "please choose a folder without spaces or [ ] in its path, e.g. C:\AETHER-AR" }
    if ($Dir.Length -gt 40) { throw "please choose a shorter folder path (at most 40 characters), e.g. C:\AETHER-AR" }
    if ($Dir -notmatch '^[A-Za-z]:\\') { throw "please choose a folder on a drive of this PC (e.g. C:\AETHER-AR), not a network path" }
    $drive = $Dir.Substring(0, 1)
    # the drive must be there and local: a mapped network drive (Z: = \\server\share) passed the rule above (31.10.)
    $psd = Get-PSDrive -Name $drive -PSProvider FileSystem -ErrorAction SilentlyContinue
    if (-not $psd) { throw "there is no drive $($drive): on this PC -- choose a folder such as C:\AETHER-AR" }
    if ("$($psd.DisplayRoot)" -like '\\*') { throw "$($drive): is a network drive ($($psd.DisplayRoot)) -- choose a folder on a local drive (e.g. C:\AETHER-AR)" }
    # (a drive Windows reports no volume for -- subst, network -- is not checked: its "No MSFT_Volume objects found" is no
    # CimException and ended the install raw, 31.10.)
    $fs = $null; try { $fs = (Get-Volume -DriveLetter $drive -ErrorAction Stop).FileSystemType } catch { }
    if ($null -ne $fs -and $fs -notin @('NTFS', 'ReFS')) { throw "$($drive): is a $fs drive -- the build needs an NTFS drive (e.g. C:)" }
    $fresh = -not (Test-Path (Join-Path $Dir '.git'))
    $free = $psd.Free / 1GB
    if ($fresh -and $free -lt 10) { throw ("only {0:N1} GB free on {1}: -- the install needs about 10 GB" -f $free, $drive) }
    Say "folder: $Dir"

    # 2. git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Step 'git'
        Say "Git is needed to fetch BT3-Recomp."
        if (-not (Ask "Install Git with winget?")) { throw "Git missing -- install it from git-scm.com and run this again" }
        # (a note on stderr is no error: under this transcript Windows PowerShell 5.1 turns every stderr line into one,
        # and 'Stop' ended the install at the first warning -- 31.10.; whether git is there is checked below)
        if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { throw "Windows' package installer 'winget' is missing. Install 'App Installer' from the Microsoft Store (or Git from git-scm.com), then run this again." }
        $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        & winget.exe install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent
        $wc = $LASTEXITCODE; $ErrorActionPreference = $old
        $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
        foreach ($p in "$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd") { if ((Test-Path $p) -and (($env:PATH -split ';') -notcontains $p)) { $env:PATH = "$p;$env:PATH" } }
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            # winget's exit code says why (it was ignored: every failure read "installed but not found yet", 31.10.)
            if ($wc -eq 0) { throw "Git was installed but is not found yet -- close this window and run the installer again" }
            $hex = '0x{0:X8}' -f [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$wc), 0)
            if ($hex -in '0x8A15002B', '0x8A150061') { throw "winget says Git is already installed ($hex), but this installer cannot find it -- add it to PATH or reinstall it (from git-scm.com), then run this again" }
            throw "winget could not install Git (code $hex) -- did you allow the Windows prompt? Update 'App Installer' in the Microsoft Store, or install Git from git-scm.com, then run this again"
        }
        if ($wc -eq 0) { Note-Tool 'Git.Git' }
    }
    # git writes its progress to stderr: not an error here, the exit code says that. (Not named "Git": PowerShell
    # names ignore case, and a function "Git" calling "git" called itself until the call depth overflowed.)
    function Run-Git {
        $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        & git.exe -c core.longpaths=true @args
        $code = $LASTEXITCODE; $ErrorActionPreference = $old
        if ($code -ne 0) { throw "git $($args -join ' ') failed (exit $code)" }
    }

    # 3. BT3-Recomp at the mod's version -- that one commit, without the history (--depth 1; GitHub hands out a commit by
    #    its id): a full clone kept ~1 GB of history in .git that the player never uses. The submodules likewise.
    Step 'fetch'
    if ($fresh) {
        if ((Test-Path $Dir) -and (Get-ChildItem $Dir -Force | Select-Object -First 1)) { throw "$Dir is not empty -- choose a new or empty folder" }
        Say "fetching BT3-Recomp $($base.commit.Substring(0, 7)) from GitHub ..."
        Run-Git init -q $Dir
        Run-Git -C $Dir remote add origin $base.repo
        Run-Git -C $Dir fetch --depth 1 origin $base.commit
    } else {
        $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'   # (two checks: their stderr is no error)
        $url = (& git.exe -C $Dir remote get-url origin 2>$null)
        & git.exe -C $Dir cat-file -e "$($base.commit)^{commit}" 2>$null
        $haveBase = $LASTEXITCODE -eq 0; $ErrorActionPreference = $old
        if ($url -ne $base.repo) { throw "$Dir holds another git project ($url) -- choose another folder" }
        Say "updating the install in $Dir (memory card and settings stay)"
        if (-not $haveBase) { Run-Git -C $Dir fetch --depth 1 origin $base.commit }   # (a full install from before 1.0.9 too)
    }
    Run-Git -C $Dir config core.longpaths true
    Run-Git -C $Dir checkout -q -f --detach $base.commit
    Run-Git -C $Dir reset -q --hard $base.commit   # (an update: the previous version's changes go)
    Run-Git -C $Dir submodule update --init --recursive --force --depth 1

    # 4. The mod (into the index first, then the files: the files come out with this PC's line endings, like git's own)
    Step 'mod'
    Say "putting the mod on it ..."
    Run-Git -C $Dir apply --check --cached --binary $patch
    Run-Git -C $Dir apply --cached --binary --whitespace=nowarn $patch
    Run-Git -C $Dir checkout -f -- .
    if (-not (Test-Path (Join-Path $Dir 'ar\install.ps1'))) { throw "the mod's files are not in $Dir after the patch" }

    # 5. The build from the ISO (ar\install.ps1 asks before each install, unless -Yes; the build's own log is
    #    build\setup.log)
    $ia = @{ Iso = $Iso }; if ($Yes) { $ia.Yes = $true }; if ($NoShortcuts) { $ia.NoShortcuts = $true }
    Step 'tools'   # (ar\install.ps1 says it too; said here as well, so the list moves on even with an older one)
    & (Join-Path $Dir 'ar\install.ps1') @ia
    Say "AETHER AR $($base.version) is installed in $Dir."
    Step 'done'
    if (-not $NoLaunch) {
        # (minimized outside, hidden inside: Start-Process -WindowStyle Hidden hides the WinForms window too, and a normal
        # start leaves a Windows Terminal window in the taskbar on Windows 11 -- review 01.11.)
        Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Join-Path $Dir 'ar\AetherAR.ps1')`""
        Say "the AETHER AR window opens now (later: the desktop shortcut 'AETHER AR')."
    }
    try { Stop-Transcript | Out-Null } catch { }
    exit 0
} catch {
    Write-Host "[AETHER AR] FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[AETHER AR] the log: $log (and, once the build has started, build\setup.log in the install folder)" -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}
