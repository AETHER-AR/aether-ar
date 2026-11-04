# AETHER AR -- the Setup window. "Install AETHER AR.cmd" opens it (no console): choose the disc and folder, press
# Install, and follow the plain step list without needing to use a terminal.
# The work itself is setup\install-aether-ar.ps1 (-Iso -Dir -Yes -NoLaunch -NoTranscript), run hidden with its output
# redirected to a work file; this window reads that file: "[step] <id>" lines move the list, "FAILED: <why>" is the
# reason. install-log.txt (next to the .cmd) is written by this window: everything but the compilers' warning flood
# (19 MB of it in a full build -- build\setup.log in the install folder keeps all of that).
#
# QA only (inert otherwise): AETHER_SETUP_SNAPSHOT=<folder> renders every page to PNGs and closes;
# AETHER_SETUP_AUTO=1 with AETHER_SETUP_ISO / AETHER_SETUP_DIR installs without clicks and writes the outcome to
# AETHER_SETUP_RESULT; AETHER_SETUP_SHOTS=<folder> saves the window once a minute; AETHER_SETUP_NOSHORTCUTS=1;
# AETHER_SETUP_KNOWN=<folder> stands in for the install Windows knows (HKCU:\Software\AETHER-AR InstallDir).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
function Say-Box($m, $icon = 'Warning') { [System.Windows.Forms.MessageBox]::Show($m, 'AETHER AR Setup', 'OK', $icon) | Out-Null }
$here = $PSScriptRoot; $pkg = Split-Path -Parent $here
$installer = Join-Path $here 'install-aether-ar.ps1'; $checkIso = Join-Path $here 'check-iso.ps1'
$log = Join-Path $pkg 'install-log.txt'
# the installer's raw output goes to a folder with no [ ] in its path (Start-Process -Redirect* takes wildcards: a
# package unpacked to "...\AETHER-AR [1]\" could not start the install at all -- review 01.11.)
$work = Join-Path $env:LOCALAPPDATA 'AETHER-AR-setup'
$raw = Join-Path $work 'output.txt'; $errLog = Join-Path $work 'errors.txt'

try {   # (anything that goes wrong before the window shows: said, and written next to the .cmd -- not a silent nothing)
# any error inside a click or a timer: a plain box and a line in the log, never .NET's "Unhandled exception" dialog
[System.Windows.Forms.Application]::SetUnhandledExceptionMode('CatchException')
[System.Windows.Forms.Application]::add_ThreadException({ param($s, $e)
    try { Log-Write "SETUP WINDOW ERROR: $($e.Exception.Message)" } catch { }
    Say-Box "Something went wrong in the Setup window:`n`n$($e.Exception.Message)`n`nIf it happens again, send install-log.txt (next to ""Install AETHER AR.cmd"")." 'Error' })

# one Setup window at a time (the install itself has its own lock in install-aether-ar.ps1)
$guiLock = New-Object System.Threading.Mutex($false, 'Local\AetherAR-setup-window')
$own = $false; try { $own = $guiLock.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $own = $true }
if (-not $own) { Say-Box 'AETHER AR Setup is already open (look in the taskbar).' 'Information'; exit 3 }
foreach ($p in $installer, $checkIso, (Join-Path $pkg 'mod\aether-ar.patch'), (Join-Path $pkg 'mod\BASE')) {
    if (-not (Test-Path -LiteralPath $p)) { Say-Box "The package is incomplete ($([IO.Path]::GetFileName($p)) is missing). Download the ZIP again and unpack all of it (right-click > Extract All)." 'Error'; exit 1 }
}
New-Item -ItemType Directory -Force -Path $work | Out-Null
$version = ''
foreach ($l in (Get-Content -LiteralPath (Join-Path $pkg 'mod\BASE'))) { if ($l -match '^\s*version\s*=\s*(\S+)') { $version = $matches[1] } }
# the PC stays awake while it installs (30-60 minutes; it slept half-way before -- review 01.11.)
try { Add-Type -Namespace AetherAR -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' } catch { }
function Keep-Awake($on) { try { [void][AetherAR.Power]::SetThreadExecutionState($(if ($on) { [uint32]2147483649 } else { [uint32]2147483648 })) } catch { } }

# ---- look (the AETHER AR window's colours)
$orange = [System.Drawing.Color]::FromArgb(255, 140, 0); $dark = [System.Drawing.Color]::FromArgb(24, 26, 32)
$panel = [System.Drawing.Color]::FromArgb(36, 39, 48); $silver = [System.Drawing.Color]::FromArgb(170, 176, 188)
$green = [System.Drawing.Color]::FromArgb(90, 210, 130); $red = [System.Drawing.Color]::FromArgb(255, 110, 110)
$white = [System.Drawing.Color]::White; $dim = [System.Drawing.Color]::FromArgb(95, 100, 112)
$sym = @{ ok = [string][char]0x2713; bad = [string][char]0x2717; now = [string][char]0x25CF; wait = [string][char]0x25CB }
function Font($size, $bold = $false, $name = 'Segoe UI') { New-Object System.Drawing.Font($name, $size, $(if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular })) }
function Nice([string]$s) { $s.Replace(' -- ', " $([char]0x2013) ") }   # (the scripts' ASCII "--" as a real dash on screen)
# a message from the installers, as the window says it: a capital first letter, and no "run this again" (here it is a button)
function Gui-Text([string]$m) {
    $m = "$m".Trim(); if (-not $m) { return $m }
    $m = $m.Replace(', then run this again', ', then press Try again').Replace(' and run this again', ' and press Try again').Replace(' then run this again', ' then press Try again').Replace('run the installer again', 'press Try again')
    Nice ($m.Substring(0, 1).ToUpper() + $m.Substring(1))
}
function Label($parent, $text, $x, $y, $w, $h, $size = 10, $bold = $false, $color = $white) {
    $l = New-Object System.Windows.Forms.Label; $l.Text = Nice $text; $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, $h); $l.Font = Font $size $bold; $l.ForeColor = $color; $l.BackColor = [System.Drawing.Color]::Transparent
    $parent.Controls.Add($l); return $l
}
function Button($parent, $text, $x, $y, $w, $h, $accent = $false) {
    $b = New-Object System.Windows.Forms.Button; $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h); $b.FlatStyle = 'Flat'; $b.FlatAppearance.BorderColor = $orange; $b.Cursor = 'Hand'
    $b.Font = Font $(if ($accent) { 12 } else { 10 }) $accent
    $b.BackColor = $(if ($accent) { $orange } else { $panel }); $b.ForeColor = $(if ($accent) { [System.Drawing.Color]::Black } else { $white })
    $parent.Controls.Add($b); return $b
}
function Set-Accent($b, $on) {   # (a disabled flat button keeps its colour: greyed by hand)
    $b.Enabled = $on; $b.BackColor = $(if ($on) { $orange } else { $panel }); $b.ForeColor = $(if ($on) { [System.Drawing.Color]::Black } else { $dim })
    $b.FlatAppearance.BorderColor = $(if ($on) { $orange } else { $dim })
}

$f = New-Object System.Windows.Forms.Form
# 628 high inside: fits a 1080p screen at 150 % (about 680 usable) without scrolling
$f.Text = "AETHER AR $version Setup".Replace('  ', ' '); $f.ClientSize = New-Object System.Drawing.Size(760, 628)
$f.StartPosition = 'CenterScreen'; $f.BackColor = $dark; $f.ForeColor = $white; $f.FormBorderStyle = 'FixedSingle'
$f.MaximizeBox = $false; $f.Font = Font 10
try { $f.Icon = New-Object System.Drawing.Icon((Join-Path $here 'aether-ar.ico')) } catch { }   # (AETHER AR's own mark; an older package without it keeps the plain one)
# header (all pages)
Label $f 'AETHER AR' 26 12 210 44 24 $true $orange | Out-Null
Label $f "Setup  v$version" 236 28 200 24 10 $false $silver | Out-Null
Label $f 'Dragon Ball Z: Budokai Tenkaichi 3 in your real room, on Meta Quest' 28 56 700 22 10 $false $silver | Out-Null
$rule = New-Object System.Windows.Forms.Panel; $rule.Location = New-Object System.Drawing.Point(28, 84); $rule.Size = New-Object System.Drawing.Size(704, 2); $rule.BackColor = $orange; $f.Controls.Add($rule)
function Page { $p = New-Object System.Windows.Forms.Panel; $p.Location = New-Object System.Drawing.Point(0, 88); $p.Size = New-Object System.Drawing.Size(760, 540); $p.BackColor = $dark; $p.Visible = $false; $f.Controls.Add($p); return $p }
$pgSetup = Page; $pgRun = Page; $pgDone = Page; $pgFail = Page
function Show-Page($p) { foreach ($q in $pgSetup, $pgRun, $pgDone, $pgFail) { $q.Visible = ($q -eq $p) }; $p.BringToFront() }

# ================= page 1: disc, folder, install
Label $pgSetup '1   Your game disc' 28 12 400 26 13 $true | Out-Null
$drop = New-Object System.Windows.Forms.Panel; $drop.Location = New-Object System.Drawing.Point(28, 44); $drop.Size = New-Object System.Drawing.Size(704, 92); $drop.BackColor = $panel
$pgSetup.Controls.Add($drop)
$drop.Add_Paint({ param($s, $e)
    $pen = New-Object System.Drawing.Pen($(if ($script:isoOk) { $green } else { $silver }), 2); $pen.DashStyle = 'Dash'
    $e.Graphics.DrawRectangle($pen, 1, 1, $s.Width - 3, $s.Height - 3); $pen.Dispose() })
$dropHint = 'Drag your Budokai Tenkaichi 3 disc image (.iso) here'; $nameHint = 'You need your own copy: the USA version (SLUS-21678), as a plain .iso file.'
$dropText = Label $drop $dropHint 22 18 470 26 12 $true
$dropName = Label $drop $nameHint 22 50 480 24 9.5 $false $silver
$pick = Button $drop 'Choose the ISO...' 516 24 166 44
$isoState = Label $pgSetup '' 28 142 704 42 10 $false $silver
$isoState.AutoEllipsis = $true; $tips = New-Object System.Windows.Forms.ToolTip

Label $pgSetup '2   Where to install' 28 190 400 26 13 $true | Out-Null
$dirBox = New-Object System.Windows.Forms.TextBox; $dirBox.Location = New-Object System.Drawing.Point(28, 222); $dirBox.Size = New-Object System.Drawing.Size(560, 30)
$dirBox.Font = Font 12; $dirBox.BackColor = $panel; $dirBox.ForeColor = $white; $dirBox.BorderStyle = 'FixedSingle'; $dirBox.Text = 'C:\AETHER-AR'
$pgSetup.Controls.Add($dirBox)
$change = Button $pgSetup 'Change...' 600 221 132 31
$dirState = Label $pgSetup '' 28 258 704 42 10 $false $silver

$info = New-Object System.Windows.Forms.Panel; $info.Location = New-Object System.Drawing.Point(28, 304); $info.Size = New-Object System.Drawing.Size(704, 112); $info.BackColor = $panel
$pgSetup.Controls.Add($info)
Label $info 'What happens' 16 10 300 22 10 $true | Out-Null
Label $info ("Setup downloads what the game needs (BT3-Recomp, Git, Python, the Visual Studio C++ tools) and builds " +
             "the game from your disc. The first install takes 30-60 minutes, an update a few minutes.") 16 32 676 40 10 $false $silver | Out-Null
Label $info 'Windows will ask for permission a few times: click Yes.' 16 76 676 24 10 $true $orange | Out-Null
$linkState = Label $pgSetup '' 28 424 704 24 10 $false $silver
$linkHelp = New-Object System.Windows.Forms.LinkLabel; $linkHelp.Text = 'Get the Meta Horizon Link app: meta.com/quest/setup'; $linkHelp.Location = New-Object System.Drawing.Point(28, 448)
$linkHelp.Size = New-Object System.Drawing.Size(500, 22); $linkHelp.LinkColor = $orange; $linkHelp.ActiveLinkColor = $orange; $linkHelp.Font = Font 10; $linkHelp.Visible = $false
$linkHelp.Add_LinkClicked({ Start-Process 'https://www.meta.com/quest/setup/' }); $pgSetup.Controls.Add($linkHelp)
$close1 = Button $pgSetup 'Close' 28 484 120 40
$install = Button $pgSetup 'Install' 552 478 180 50 $true
$f.AcceptButton = $install

# ================= page 2: progress
$runTitle = Label $pgRun 'Installing AETHER AR' 28 12 700 30 15 $true
Label $pgRun 'The first install takes 30-60 minutes. You can use the PC meanwhile -- keep this window open.' 28 46 704 22 10 $false $silver | Out-Null
$steps = @(
    @{ id = 'check'; text = 'Checking your game disc'; w = 3; secs = 15 },
    @{ id = 'git'; text = 'Getting Git'; w = 4; secs = 90 },
    @{ id = 'fetch'; text = 'Downloading BT3-Recomp'; w = 10; secs = 180 },
    @{ id = 'mod'; text = 'Adding the AETHER AR mod'; w = 3; secs = 20 },
    @{ id = 'tools'; text = 'Setting up the build tools (Python, Visual Studio C++)'; w = 20; secs = 900 },
    @{ id = 'build'; text = 'Building the game from your disc -- the longest part'; w = 55; secs = 1800 },
    @{ id = 'finish'; text = 'Finishing: headset tools, shortcuts'; w = 5; secs = 60 })
$y = 80
foreach ($s in $steps) {
    $s.icon = Label $pgRun $sym.wait 36 $y 30 30 14 $false $dim; $s.icon.Font = Font 14 $false 'Segoe UI Symbol'
    $s.label = Label $pgRun $s.text 72 ($y + 3) 640 26 11 $false $dim
    $y += 36
}
$track = New-Object System.Windows.Forms.Panel; $track.Location = New-Object System.Drawing.Point(28, 342); $track.Size = New-Object System.Drawing.Size(704, 12); $track.BackColor = $panel
$fill = New-Object System.Windows.Forms.Panel; $fill.Location = New-Object System.Drawing.Point(0, 0); $fill.Size = New-Object System.Drawing.Size(0, 12); $fill.BackColor = $orange
$track.Controls.Add($fill); $pgRun.Controls.Add($track)
$pct = Label $pgRun '' 28 360 704 22 10 $true
$detail = Label $pgRun '' 28 384 704 22 9 $false $silver; $detail.AutoEllipsis = $true
# Windows' permission prompts: said while a step may bring one, and loudly while one is open (a hidden installer's
# prompt can sit as a flashing shield in the taskbar -- review 01.11.)
$permit = Label $pgRun '' 28 414 704 44 10 $true $orange
$cancel = Button $pgRun 'Cancel' 28 484 120 40
$openLog1 = Button $pgRun 'Open the log' 160 484 140 40

# ================= page 3: done
$doneIcon = Label $pgDone $sym.ok 24 4 70 70 40 $false $green; $doneIcon.Font = Font 40 $false 'Segoe UI Symbol'
$doneTitle = Label $pgDone 'AETHER AR is installed.' 100 20 620 34 17 $true
Label $pgDone ('Start it with the desktop shortcut "AETHER AR", or type AETHER in Start. ' +
               'To keep it in the taskbar: right-click it in Start > Pin to taskbar.') 28 72 704 42 10.5 $false | Out-Null
# the Link app's own words (Meta Horizon Link 1.115: Settings > General "OpenXR Runtime" / "Set Meta Horizon Link as
# active" / "Unknown sources", Settings > Beta toggles)
$prep = New-Object System.Windows.Forms.Panel; $prep.Location = New-Object System.Drawing.Point(28, 118); $prep.Size = New-Object System.Drawing.Size(704, 146); $prep.BackColor = $panel
$pgDone.Controls.Add($prep)
Label $prep 'Before you play (once)' 14 8 400 22 10.5 $true $orange | Out-Null
Label $prep ("1.  In the Meta Horizon Link app on this PC (formerly Meta Quest Link):`n" +
             "     Settings > General: OpenXR Runtime > Set Meta Horizon Link as active.`n" +
             "     Settings > General: Unknown sources on (for apps not from the Meta store).`n" +
             "     Settings > Beta: turn on Developer runtime features, Passthrough over Meta Horizon Link,`n" +
             "     Spatial data over Meta Horizon Link.`n" +
             "2.  In the headset: Settings > Physical space > Space setup -- set up this room (walls, desk / table).") 14 32 682 112 9.5 $false | Out-Null
$play = New-Object System.Windows.Forms.Panel; $play.Location = New-Object System.Drawing.Point(28, 270); $play.Size = New-Object System.Drawing.Size(704, 112); $play.BackColor = $panel
$pgDone.Controls.Add($play)
Label $play 'Every time' 14 8 400 22 10.5 $true $orange | Out-Null
Label $play ("1.  Press Start in the AETHER AR window, then put the headset on and turn on Link (Quick Settings > Link).`n" +
             "2.  Menus: left stick + A, B = back. The fight starts on your desk by itself -- look around for it.`n" +
             "     To move it: point a controller at another spot and pull the trigger.`n" +
             "3.  To end: take the headset off and press Stop in the AETHER AR window.") 14 32 682 78 9.5 $false | Out-Null
# where the disc is (M5) and where the rest is written down: set by Fill-Done, when the install is through
$keepIso = Label $pgDone '' 28 388 704 42 9.5 $false $white; $keepIso.AutoEllipsis = $true
$startHere = Label $pgDone '' 28 432 704 40 9.5 $false $silver
$close3 = Button $pgDone 'Close' 28 484 120 40
$startAr = Button $pgDone 'Start AETHER AR' 492 478 240 50 $true

# ================= page 4: stopped
$failIcon = Label $pgFail '!' 34 4 60 70 40 $true $red
$failTitle = Label $pgFail 'The install stopped.' 100 20 620 34 17 $true
$why = New-Object System.Windows.Forms.TextBox; $why.Multiline = $true; $why.ReadOnly = $true; $why.WordWrap = $true; $why.ScrollBars = 'Vertical'
$why.Location = New-Object System.Drawing.Point(28, 80); $why.Size = New-Object System.Drawing.Size(704, 120); $why.Font = Font 11
$why.BackColor = $panel; $why.ForeColor = $white; $why.BorderStyle = 'None'; $pgFail.Controls.Add($why)
Label $pgFail ("Fix what it says, then press Try again. What is already done is kept, so the next run is quicker.`n`n" +
               "If it keeps failing, send install-log.txt (in the folder with ""Install AETHER AR.cmd"") to whoever gave you AETHER AR.") 28 212 704 80 10 $false $silver | Out-Null
$close4 = Button $pgFail 'Close' 28 484 120 40
$openLog4 = Button $pgFail 'Open the log' 160 484 140 40
$retry = Button $pgFail 'Try again' 552 478 180 50 $true

# ================= state + checks
$script:isoOk = $false; $script:iso = ''; $script:dirOk = $false; $script:mode = 'new'; $script:dir = ''; $script:proc = $null; $script:started = Get-Date
function Update-Install {
    Set-Accent $install ($script:isoOk -and $script:dirOk)
    $install.Text = @{ new = 'Install'; continue = 'Continue'; update = 'Update'; repair = 'Reinstall' }[$script:mode]
}
function Set-Iso([string]$path) {
    $script:pendingIso = ''; if ($isoTimer) { $isoTimer.Stop() }   # (a disc chosen now wins over the install's own, see Take-Install-Iso)
    $path = "$path".Trim().Trim('"').Trim()
    $script:isoOk = $false; $script:iso = ''; $dropText.Text = Nice $dropHint; $dropName.Text = $nameHint; $dropName.ForeColor = $silver
    $fail = {   # (the box shows the hint again: what is in it is never a disc that failed)
        param($m) $isoState.ForeColor = $red; $isoState.Text = Gui-Text "$($sym.bad)  $m"; $tips.SetToolTip($isoState, $isoState.Text); $drop.Invalidate(); Update-Install }
    if (-not $path) { & $fail 'Choose your disc image (.iso).'; return }
    if (Test-Path -LiteralPath $path -PathType Container) { & $fail "'$(Split-Path -Leaf $path)' is a folder -- drag the .iso file itself."; return }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { & $fail "There is no file '$path'."; return }
    $path = (Resolve-Path -LiteralPath $path).ProviderPath
    # AETHER AR reads the disc image at every start (start-ar.ps1 hands it to the game): one that Windows or the player
    # deletes later breaks the game the next day. Dragged straight out of the ZIP, Explorer hands over a copy in the
    # temp folder (%TEMP%\Temp1_<zip>\...) that Windows cleans up -- refused. One inside this Setup folder is taken,
    # with a note: that folder is what people delete after installing.
    $inPkg = $path.StartsWith($pkg.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)
    $tmpRoots = @([IO.Path]::GetTempPath(), $env:TEMP, $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Temp' })) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') + '\' }
    $inTemp = (-not $inPkg) -and [bool]@($tmpRoots | Where-Object { $path.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count
    if ($inTemp -or $path -match '\\Temp\d*_[^\\]*\.zip\\') {
        if ($path -match '\\Temp\d*_[^\\]*\.zip\\|\\(7z[A-Z]?[0-9A-F]+|Rar\$[^\\]+)\\') { & $fail 'You dragged it out of the ZIP. Unpack the ZIP to a folder you keep (e.g. Documents\BT3), then choose the .iso there.' }
        else { & $fail "This .iso is in Windows' temporary folder, which Windows cleans up. Move it to a folder you keep (e.g. Documents\BT3), then choose it there." }
        return
    }
    $isoState.ForeColor = $silver; $isoState.Text = "Checking $([IO.Path]::GetFileName($path)) ..."; $f.UseWaitCursor = $true; $f.Refresh()
    try {
        & $checkIso -Iso $path -Work (Join-Path $work 'iso-check')
        $script:isoOk = $true; $script:iso = $path
        $dropText.Text = [IO.Path]::GetFileName($path); $dropName.Text = Split-Path -Parent $path
        if ($inPkg) {
            $isoState.ForeColor = $orange
            $isoState.Text = Nice "$($sym.ok)  Checked. This .iso is inside the Setup folder. AETHER AR reads it every time you play -- move it e.g. to Documents first, then choose it again."
            $tips.SetToolTip($isoState, $isoState.Text)
        } else { $isoState.ForeColor = $green; $isoState.Text = Nice "$($sym.ok)  Budokai Tenkaichi 3 (USA) -- checked, ready."; $tips.SetToolTip($isoState, '') }
    } catch { & $fail "$([IO.Path]::GetFileName($path)): $($_.Exception.Message)" }
    finally { $f.UseWaitCursor = $false }
    $drop.Invalidate(); Update-Install
}
function Check-Dir {
    $script:dirOk = $false; $script:mode = 'new'
    $d = $dirBox.Text.Trim().Trim('"').Trim(); if ($d.Length -gt 3) { $d = $d.TrimEnd('\') }
    $bad = $null
    if (-not $d) { $bad = 'Type a folder, e.g. C:\AETHER-AR.' }
    elseif ($d -notmatch '^[A-Za-z]:\\.') { $bad = 'Choose a folder on a drive of this PC, e.g. C:\AETHER-AR.' }
    elseif ($d.IndexOfAny([char[]]'<>|"?*') -ge 0 -or $d.IndexOf(':', 2) -ge 0) { $bad = 'A folder name cannot contain : * ? " < > | -- e.g. C:\AETHER-AR.' }
    elseif ($d -match '[\s\[\]]') { $bad = 'No spaces or [ ] in the path, please -- e.g. C:\AETHER-AR.' }
    elseif ($d.Length -gt 40) { $bad = 'A shorter path, please (at most 40 characters) -- e.g. C:\AETHER-AR.' }
    if (-not $bad) {
        $psd = Get-PSDrive -Name $d.Substring(0, 1) -PSProvider FileSystem -ErrorAction SilentlyContinue
        if (-not $psd) { $bad = "There is no drive $($d.Substring(0, 2)) on this PC." }
        elseif ("$($psd.DisplayRoot)" -like '\\*') { $bad = "$($d.Substring(0, 2)) is a network drive -- choose a folder on this PC, e.g. C:\AETHER-AR." }
    }
    if ($bad) { $dirState.ForeColor = $red; $dirState.Text = Nice "$($sym.bad)  $bad"; Update-Install; return }
    $script:dir = $d; $free = $psd.Free / 1GB
    if (Test-Path -LiteralPath (Join-Path $d '.git')) {
        $script:dirOk = $true; $dirState.ForeColor = $green
        if (Test-Path -LiteralPath (Join-Path $d 'build\ps2xRuntime\ps2EntryRunner.exe')) {   # (finished: the installer's own success test)
            $old = ''; try { $old = (Get-Content -LiteralPath (Join-Path $d 'ar\VERSION') -TotalCount 1 -ErrorAction Stop).Trim() } catch { }
            if ($old -eq $version) { $script:mode = 'repair'; $dirState.Text = Nice "$($sym.ok)  AETHER AR $old is installed here: Setup installs it again (a repair). Your memory card and settings stay." }
            else { $script:mode = 'update'; $dirState.Text = Nice "$($sym.ok)  AETHER AR $old is installed here: Setup updates it to $version. Your memory card and settings stay." }
        } else { $script:mode = 'continue'; $dirState.Text = Nice "$($sym.ok)  An unfinished AETHER AR install is here -- Setup continues it." }
        Take-Install-Iso $d   # (the disc this install already uses, when none is chosen yet)
    } elseif ((Test-Path -LiteralPath $d) -and (Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        $dirState.ForeColor = $red; $dirState.Text = Nice "$($sym.bad)  This folder is not empty -- choose a new or empty one (e.g. $(Join-Path $d 'AETHER-AR'))."
    } elseif ($free -lt 10) {
        $dirState.ForeColor = $red; $dirState.Text = Nice ("{0}  Only {1:N1} GB free on {2} -- the install needs about 10 GB (up to 20 GB on C: when the Visual Studio tools are missing)." -f $sym.bad, $free, $d.Substring(0, 2))
    } else {
        $script:dirOk = $true; $dirState.ForeColor = $green
        $dirState.Text = Nice ("{0}  New install -- needs about 10 GB (up to 20 GB on C:); {1} has {2:N0} GB free." -f $sym.ok, $d.Substring(0, 2), $free)
    }
    Update-Install
}
function Check-Link {   # (not needed to install -- to play; said here so it is set up meanwhile)
    $rt = $null; try { $rt = (Get-ItemProperty 'HKLM:\SOFTWARE\Khronos\OpenXR\1' -ErrorAction Stop).ActiveRuntime } catch { }
    # (the PC app is "Meta Horizon Link" today -- 1.115 in its uninstall entry; it was "Meta Quest Link")
    if ($rt -and $rt -match 'oculus|meta') { $linkState.ForeColor = $green; $linkState.Text = Nice "$($sym.ok)  Meta Horizon Link is set up on this PC."; $linkHelp.Visible = $false }
    else { $linkState.ForeColor = $orange; $linkState.Text = Nice '!  Meta Horizon Link (formerly Meta Quest Link) is not set up yet -- you need it to play, not to install.'; $linkHelp.Visible = $true }
}
# an existing install (S11): its disc taken over, so an update is one click. Started by a timer: the disc check takes a
# moment, and at startup the window should be on screen first.
$script:pendingIso = ''; $script:isoFromDir = ''
$isoTimer = New-Object System.Windows.Forms.Timer; $isoTimer.Interval = 150
$isoTimer.Add_Tick({ $isoTimer.Stop(); $p = $script:pendingIso; $script:pendingIso = ''; if ($p -and -not $script:isoOk) { Set-Iso $p } })
function Take-Install-Iso([string]$d) {
    if ($script:isoOk -or $script:isoFromDir -eq $d) { return }
    $script:isoFromDir = $d
    $p = ''; try { $p = [string](Get-Content -LiteralPath (Join-Path $d 'ar\config.json') -Raw -ErrorAction Stop | ConvertFrom-Json).iso } catch { }
    if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { $script:pendingIso = $p; $isoTimer.Start() }
}
# AETHER AR of this folder running: the update would fail at the very end (the build cannot replace a running
# ps2EntryRunner.exe), and the window would start the old game meanwhile
function Running-In([string]$d) {
    $exe = Join-Path $d 'build\ps2xRuntime\ps2EntryRunner.exe'
    if (@(Get-Process ps2EntryRunner -ErrorAction SilentlyContinue | Where-Object { $_.Path -and [string]::Equals($_.Path, $exe, [StringComparison]::OrdinalIgnoreCase) }).Count) { return $true }
    $arD = Join-Path $d 'ar'; $forms = @("$arD\start-ar.ps1", "$arD\AetherAR.ps1", "$($arD.Replace("'", "''"))\AetherAR.ps1")
    foreach ($p in @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue)) {
        $cl = "$($p.CommandLine)"; foreach ($s in $forms) { if ($cl.IndexOf($s, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true } }
    }
    return $false
}

# ---- disc: button and drag & drop (only on the first page)
$pick.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Choose your Budokai Tenkaichi 3 USA disc image (.iso)'; $dlg.Filter = 'PS2 disc image (*.iso)|*.iso|All files (*.*)|*.*'
    $dl = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'; if (Test-Path -LiteralPath $dl) { $dlg.InitialDirectory = $dl }
    if ($dlg.ShowDialog($f) -eq 'OK') { Set-Iso $dlg.FileName }
})
$onEnter = { param($s, $e) if ($pgSetup.Visible -and $e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = 'Copy' } }
$onDrop = { param($s, $e) if (-not $pgSetup.Visible) { return }; $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop); if ($files) { $f.Activate(); Set-Iso @($files)[0] } }
foreach ($c in @($f, $pgSetup, $drop, $dropText, $dropName, $isoState)) { $c.AllowDrop = $true; $c.Add_DragEnter($onEnter); $c.Add_DragDrop($onDrop) }
# ---- folder
$dirBox.Add_TextChanged({ Check-Dir })
$change.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    $fb.Description = 'Where should AETHER AR go? (A new or empty folder -- no spaces in the path.)'; $fb.ShowNewFolderButton = $true
    if ($fb.ShowDialog($f) -eq 'OK') {
        $d = $fb.SelectedPath
        # a drive or a folder with other things in it: AETHER-AR inside it
        if ($d.Length -le 3 -or ((-not (Test-Path -LiteralPath (Join-Path $d '.git'))) -and (Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue | Select-Object -First 1))) { $d = Join-Path $d 'AETHER-AR' }
        $dirBox.Text = $d
    }
})

# ================= the log (written here, without the compilers' warning flood)
$script:logW = $null
function Log-Open {
    $fs = New-Object System.IO.FileStream($log, 'Create', 'Write', 'ReadWrite')   # (Notepad can open it meanwhile)
    $script:logW = New-Object System.IO.StreamWriter($fs, (New-Object System.Text.UTF8Encoding($false))); $script:logW.AutoFlush = $true
}
function Log-Write([string]$s) { if ($script:logW) { try { $script:logW.WriteLine($s) } catch { } } }
function Log-Close { if ($script:logW) { try { $script:logW.Dispose() } catch { }; $script:logW = $null } }
# compiler snippets and warnings, the build's progress counter, git's progress: build\setup.log has them
$noise = '^\s*\d*\s*\|' + '|^\s*[\^~]+\s*$' + '|In file included from' + '|:\s*(warning|note)\b' + '|warnings? generated' + '|^\s*note:' + '|^\[\d+/\d+\]' +
         '|^-- \[download \d+% complete\]' +
         '|^(remote: )?(Receiving|Resolving|Counting|Compressing|Enumerating) (objects|deltas)' + '|^Updating files:'

# ================= the install
$script:active = ''; $script:activeSince = Get-Date; $script:frac = 0.0; $script:shown = 0.0; $script:bigN = 0
$script:reason = ''; $script:sawDone = $false; $script:pos = 0L; $script:rest = ''
# the hidden installer writes its output in the console's code page
$script:enc = [Text.Encoding]::Default; try { $script:enc = [Text.Encoding]::GetEncoding([Console]::OutputEncoding.CodePage) } catch { }
function Set-Step([string]$id) {
    $i = -1; for ($k = 0; $k -lt $steps.Count; $k++) { if ($steps[$k].id -eq $id) { $i = $k } }
    if ($id -eq 'done') { $i = $steps.Count }
    if ($i -lt 0) { return }
    for ($k = 0; $k -lt $steps.Count; $k++) {
        $s = $steps[$k]
        if ($k -lt $i) { $s.icon.Text = $sym.ok; $s.icon.ForeColor = $green; $s.label.ForeColor = $white; $s.label.Font = Font 11 }
        elseif ($k -eq $i) { $s.icon.Text = $sym.now; $s.icon.ForeColor = $orange; $s.label.ForeColor = $white; $s.label.Font = Font 11 $true }
        else { $s.icon.Text = $sym.wait; $s.icon.ForeColor = $dim; $s.label.ForeColor = $dim; $s.label.Font = Font 11 }
    }
    if ($id -ne $script:active) { $script:active = $id; $script:activeSince = Get-Date; $script:frac = 0.0; $script:bigN = 0 }
    if ($id -eq 'done') { $script:sawDone = $true }
}
function Update-Bar {
    $sum = 0.0; $i = -1; for ($k = 0; $k -lt $steps.Count; $k++) { if ($steps[$k].id -eq $script:active) { $i = $k } }
    if ($script:sawDone) { $sum = 100 } elseif ($i -ge 0) {
        for ($k = 0; $k -lt $i; $k++) { $sum += $steps[$k].w }
        # inside a step: the build's own counter where it has one, else the time it usually takes (never full)
        $t = ((Get-Date) - $script:activeSince).TotalSeconds / $steps[$i].secs
        $sum += $steps[$i].w * [Math]::Min(0.97, [Math]::Max($script:frac, 0.9 * (1 - [Math]::Exp(-$t))))
    }
    $script:shown = [Math]::Max($script:shown, $sum)   # (never backwards)
    $fill.Width = [int](704 * $script:shown / 100)
    $el = (Get-Date) - $script:started
    $pct.Text = ('{0:N0} %      {1}:{2:00} min' -f $script:shown, [int][Math]::Floor($el.TotalMinutes), $el.Seconds)
    # permission prompts
    $asking = $false; try { $asking = [bool](Get-Process consent -ErrorAction SilentlyContinue) } catch { }
    if ($asking) { $permit.ForeColor = $orange; $permit.Text = 'Windows is asking for permission now: click Yes. (No window? Click the flashing shield in the taskbar.)' }
    elseif ($script:active -in 'git', 'tools') { $permit.ForeColor = $silver; $permit.Text = 'Windows may ask for permission during this step: click Yes. (No window? Look for a flashing shield in the taskbar.)' }
    else { $permit.Text = '' }
}
function Read-Line([string]$line) {
    # (the build's lines end in CR LF: split at the last CR only after dropping the line's own -- review 01.11.)
    $line = ($line.TrimEnd("`r") -split "`r")[-1].TrimEnd(); $t = $line.Trim(); if (-not $t) { return }
    if ($t -notmatch $noise) { Log-Write $line }
    if ($t -match '^\[step\]\s+(\w+)') { Set-Step $matches[1]; return }
    if ($t -match 'FAILED:\s*(.+)$') { $script:reason = $matches[1]; return }
    if ($t -match '^\[(AETHER AR|install)\]\s+(.+)$') {
        $msg = $matches[2]
        # (an older ar\install.ps1 without step lines: its own words move the list)
        if ($msg -match '^building --' -and $script:active -ne 'build') { Set-Step 'build' }
        $detail.Text = Nice $msg; return
    }
    if ($t -match '^==\s+(.+)$') { $detail.Text = $matches[1]; return }
    if ($t -match '^\[(\d+)/(\d+)\]\s+(.+)$') {
        # the build runs several counters (122 recompiler steps, then ~1700 for the game): only the biggest one so far
        $n = [int]$matches[2]
        if ($script:active -eq 'build' -and $n -ge 200 -and $n -ge $script:bigN) {
            if ($n -gt $script:bigN) { $script:bigN = $n; $script:frac = 0.0 }
            $script:frac = [Math]::Max($script:frac, [int]$matches[1] / $n)
        }
        $detail.Text = ('Compiling {0} of {1}' -f $matches[1], $n); return
    }
    if ($t -match $noise) { return }   # (the compilers' warnings: not what the player should read as "what it is doing")
    if (($t -replace '[^A-Za-z]', '').Length -ge 6) { $detail.Text = $t }
}
function Read-New {
    if (-not (Test-Path -LiteralPath $raw)) { return }
    try {
        $fs = New-Object System.IO.FileStream($raw, 'Open', 'Read', 'ReadWrite, Delete')
        try {
            if ($fs.Length -le $script:pos) { return }
            $null = $fs.Seek($script:pos, 'Begin'); $buf = New-Object byte[] ($fs.Length - $script:pos); $n = $fs.Read($buf, 0, $buf.Length); $script:pos += $n
        } finally { $fs.Dispose() }
    } catch { return }
    $text = $script:rest + $script:enc.GetString($buf, 0, $n)
    $lines = $text -split "`n"; $script:rest = $lines[-1]
    for ($k = 0; $k -lt $lines.Count - 1; $k++) { Read-Line $lines[$k] }
}
function Start-Install {
    if (($script:mode -in @('update', 'repair', 'continue')) -and (Running-In $script:dir)) {
        $m = 'Close AETHER AR first (press Stop in its window, then close it).'
        if ($env:AETHER_SETUP_AUTO -eq '1') { Show-Fail $m } else { Say-Box "$m`n`nThen press $($install.Text) again." 'Information' }
        return
    }
    Show-Page $pgRun
    foreach ($s in $steps) { $s.icon.Text = $sym.wait; $s.icon.ForeColor = $dim; $s.label.ForeColor = $dim; $s.label.Font = Font 11 }
    $runTitle.Text = $(if ($script:mode -in 'update', 'repair') { 'Updating AETHER AR' } else { 'Installing AETHER AR' })
    $script:active = ''; $script:sawDone = $false; $script:reason = ''; $script:frac = 0.0; $script:shown = 0.0; $script:bigN = 0; $script:pos = 0L; $script:rest = ''
    $script:started = Get-Date; $detail.Text = 'Starting ...'; $permit.Text = ''
    Remove-Item -LiteralPath $raw, $errLog -ErrorAction SilentlyContinue
    Log-Close; Log-Open
    Log-Write "AETHER AR $version Setup, $(Get-Date -Format 'yyyy-MM-dd HH:mm'), Windows $([Environment]::OSVersion.Version)"
    Log-Write "disc: $($script:iso)"; Log-Write "folder: $($script:dir) ($($script:mode))"; Log-Write ''
    $env:PYTHONUNBUFFERED = '1'        # (the build's own lines come as they happen, not in blocks)
    $env:AETHER_SETUP_STEPS = '1'      # (the installers print their "[step]" lines only for this window)
    $env:GIT_TERMINAL_PROMPT = '0'; $env:GCM_INTERACTIVE = 'never'   # (a git password prompt would wait unseen: it fails, and says so)
    $a = "-NoProfile -ExecutionPolicy Bypass -File `"$installer`" -Iso `"$($script:iso)`" -Dir `"$($script:dir)`" -Yes -NoLaunch -NoTranscript"
    if ($env:AETHER_SETUP_NOSHORTCUTS -eq '1') { $a += ' -NoShortcuts' }   # (QA: a test install keeps the player's desktop shortcut)
    try { $script:proc = Start-Process powershell -ArgumentList $a -WindowStyle Hidden -PassThru -RedirectStandardOutput $raw -RedirectStandardError $errLog -ErrorAction Stop }
    catch { Show-Fail "Windows did not start the installer: $($_.Exception.Message)"; return }
    $null = $script:proc.Handle   # (without it Windows PowerShell reports no exit code later)
    Keep-Awake $true
    Set-Step 'check'; Update-Bar; $timer.Start()
}
function Fill-Done {
    $iso = $script:iso
    if ($iso -and $iso.StartsWith($pkg.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $keepIso.ForeColor = $orange
        $keepIso.Text = Nice "Your disc image ($([IO.Path]::GetFileName($iso))) is inside this Setup folder. AETHER AR reads it every time you play: move it e.g. to Documents before you delete this folder, then choose it again in the AETHER AR window."
    } else {
        $keepIso.ForeColor = $white
        $keepIso.Text = Nice "Keep your disc image where it is ($iso): AETHER AR reads it every time you play. You can delete the ZIP and this Setup folder."
    }
    $tips.SetToolTip($keepIso, $keepIso.Text)
    $startHere.Text = Nice "In $($script:dir), ""AETHER AR - START HERE.txt"" has all of this again, and how to update or remove AETHER AR (Settings > Apps)."
}
function Show-Fail([string]$m) {
    $timer.Stop(); Keep-Awake $false
    $m = Gui-Text $m; $why.Text = $m.Replace("`r`n", "`n").Replace("`n", "`r`n"); Show-Page $pgFail   # (a TextBox breaks lines only at CR LF)
    Log-Write ''; Log-Write "RESULT: stopped -- $m"; Log-Close
    if ($env:AETHER_SETUP_RESULT) { try { [IO.File]::WriteAllText($env:AETHER_SETUP_RESULT, "FAILED: $m") } catch { } }
    if ($env:AETHER_SETUP_AUTO -eq '1') { $f.Close() }
}
function Finish {
    $timer.Stop(); Read-New; if ($script:rest) { Read-Line $script:rest; $script:rest = '' }
    # what went to stderr goes to the end of the log (git's and the tools' own words), without their progress lines
    $errLines = @(); try { if (Test-Path -LiteralPath $errLog) { $errLines = @(Get-Content -LiteralPath $errLog | ForEach-Object { ($_.TrimEnd("`r") -split "`r")[-1].TrimEnd() } | Where-Object { $_.Trim() -and $_ -notmatch $noise }) } } catch { }
    if ($errLines.Count) { Log-Write ''; Log-Write '---- error output ----'; foreach ($e in $errLines) { Log-Write $e } }
    $code = $script:proc.ExitCode; $script:proc = $null
    if ($code -eq 0 -and $script:sawDone) {
        Keep-Awake $false; Update-Bar
        $doneTitle.Text = $(if ($script:mode -in 'update', 'repair') { "AETHER AR is updated to $version." } else { 'AETHER AR is installed.' })
        Log-Write ''; Log-Write 'RESULT: installed'; Log-Close
        Fill-Done; Show-Page $pgDone
        if ($env:AETHER_SETUP_RESULT) { try { [IO.File]::WriteAllText($env:AETHER_SETUP_RESULT, "OK $($script:dir)") } catch { } }
        if ($env:AETHER_SETUP_AUTO -eq '1') { $f.Close() }
        return
    }
    $m = $script:reason
    if (-not $m -and $code -eq 3) { $m = 'Another AETHER AR install is already running. Let it finish (or close it), then press Try again.' }
    if (-not $m) { $m = "The installer stopped (code $code) without saying why. Open the log to see the last thing it did." }
    # the cause is often only in the tools' own words (git: "fatal: unable to access ... Could not resolve host")
    $cause = $errLines | Where-Object { $_ -match '^(fatal|error|ERROR)[: ]' } | Select-Object -Last 1
    if ($cause -match 'resolve host|Failed to connect|timed out|Connection (reset|refused)|early EOF|RPC failed|SSL|unable to access') {
        $m = "No connection to GitHub (or it broke off) -- check the internet connection, then press Try again.`n`n($cause)"
    } elseif ($cause) { $m = "$m`n`n($cause)" }
    Show-Fail $m
}
$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 500
$script:lastShot = Get-Date
$timer.Add_Tick({
    Read-New; Update-Bar
    if ($env:AETHER_SETUP_SHOTS -and ((Get-Date) - $script:lastShot).TotalSeconds -ge 60) {   # (QA: the window once a minute)
        $script:lastShot = Get-Date
        try { $bmp = New-Object System.Drawing.Bitmap($f.Width, $f.Height); $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($f.Location, [System.Drawing.Point]::Empty, $f.Size); $g.Dispose()
              $bmp.Save((Join-Path $env:AETHER_SETUP_SHOTS ('run-{0:HHmmss}.png' -f (Get-Date)))); $bmp.Dispose() } catch { }
    }
    if ($script:proc -and $script:proc.HasExited) { Finish }
})
function Stop-Install {   # true when it stopped (or nothing ran)
    if (-not $script:proc -or $script:proc.HasExited) { return $true }
    $a = [System.Windows.Forms.MessageBox]::Show("Stop the install now?`n`nWhat is done so far is kept: run Setup again later and it continues.", 'AETHER AR Setup', 'YesNo', 'Question')
    if ($a -ne 'Yes') { return $false }
    if (-not $script:proc -or $script:proc.HasExited) { return $true }   # (it finished while the question was open: its own result stands)
    $timer.Stop()
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'   # (its words on stderr are no error)
    try { & taskkill.exe /T /F /PID $script:proc.Id 2>&1 | Out-Null } catch { }
    $ErrorActionPreference = $eap
    $wasTools = $script:active -in 'git', 'tools'
    $script:proc = $null
    Show-Fail $('You stopped the install. Press Try again to continue it (what is already done is kept).' +
                $(if ($wasTools) { "`n`nA Windows installer it had started (Git, Python, Visual Studio) may still be finishing in the background: wait a few minutes before Try again." } else { '' }))
    return $true
}

$install.Add_Click({ if ($script:isoOk -and $script:dirOk) { Start-Install } })
$cancel.Add_Click({ [void](Stop-Install) })
$retry.Add_Click({ Show-Page $pgSetup; Check-Dir; Check-Link })
foreach ($b in $openLog1, $openLog4) { $b.Add_Click({ if (Test-Path -LiteralPath $log) { Start-Process notepad.exe -ArgumentList "`"$log`"" } }) }
foreach ($b in $close1, $close3, $close4) { $b.Add_Click({ $f.Close() }) }
$startAr.Add_Click({
    $launcher = Join-Path $script:dir 'ar\AetherAR.ps1'
    # minimized outside, hidden inside: Windows 11 then hands no console to Windows Terminal (a hidden start alone
    # left a "Windows PowerShell" terminal in the taskbar, and closing it closed the window -- review 01.11.)
    if (Test-Path -LiteralPath $launcher) { Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`"" }
    $f.Close()
})
$f.Add_FormClosing({ param($s, $e) if ($script:proc -and -not $script:proc.HasExited -and $env:AETHER_SETUP_AUTO -ne '1') { if (-not (Stop-Install)) { $e.Cancel = $true } } })

# ---- start
# the install Windows knows (written at install, ar\shortcuts.ps1): an update goes there, with its disc (S11) -- not a
# second 4 GB install in C:\AETHER-AR next to one in D:\
$known = $env:AETHER_SETUP_KNOWN
if (-not $known) { try { $known = [string](Get-ItemProperty -LiteralPath 'HKCU:\Software\AETHER-AR' -Name InstallDir -ErrorAction Stop).InstallDir } catch { } }
if ($known -and (Test-Path -LiteralPath (Join-Path $known 'ar\VERSION'))) { $dirBox.Text = $known }
Show-Page $pgSetup; Check-Dir; Check-Link; Update-Install
$f.Add_Shown({
    $f.Activate()
    if ($env:AETHER_SETUP_AUTO -eq '1' -or $env:AETHER_SETUP_SNAPSHOT) {   # (QA runs: on a second screen if there is one)
        $scr2 = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Select-Object -First 1
        if ($scr2) { $f.Location = $scr2.WorkingArea.Location }
    }
    if ($env:AETHER_SETUP_ISO) { Set-Iso $env:AETHER_SETUP_ISO }
    if ($env:AETHER_SETUP_DIR) { $dirBox.Text = $env:AETHER_SETUP_DIR }
    if ($env:AETHER_SETUP_AUTO -eq '1') { if ($script:isoOk -and $script:dirOk) { Start-Install } else { Show-Fail "auto: not ready ($($isoState.Text) / $($dirState.Text))" } }
    if ($env:AETHER_SETUP_SNAPSHOT) {   # QA: every page as a PNG, then closed
        $script:shot = 0
        $snap = New-Object System.Windows.Forms.Timer; $snap.Interval = 900
        $snap.Add_Tick({ param($t)
            $names = 'setup', 'run', 'done', 'fail'
            if ($script:shot -eq 1) { Show-Page $pgRun; $script:started = (Get-Date).AddMinutes(-23); Set-Step 'tools'; $permit.Text = 'Windows is asking for permission now: click Yes. (No window? Click the flashing shield in the taskbar.)'; $detail.Text = 'Visual Studio 2022 Build Tools: installing (a few GB)'; $pct.Text = '31 %      23:00 min'; $fill.Width = 218 }
            if ($script:shot -eq 2) { Fill-Done; Show-Page $pgDone }
            if ($script:shot -eq 3) { $why.Text = Gui-Text "No connection to GitHub (or it broke off) -- check the internet connection, then press Try again.`n`n(fatal: unable to access 'https://github.com/z3xox/BT3-Recomp.git/': Could not resolve host: github.com)"; Show-Page $pgFail }
            $f.Activate(); $f.Refresh(); Start-Sleep -Milliseconds 300
            $bmp = New-Object System.Drawing.Bitmap($f.Width, $f.Height); $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.CopyFromScreen($f.Location, [System.Drawing.Point]::Empty, $f.Size); $g.Dispose()
            $bmp.Save((Join-Path $env:AETHER_SETUP_SNAPSHOT ("setup-{0}.png" -f $names[$script:shot]))); $bmp.Dispose()
            $script:shot++; if ($script:shot -ge 4) { $t.Stop(); $f.Close() }
        })
        $snap.Start()
    }
})
# a screen lower than the window: the window shrinks and scrolls
$wa = [System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position).WorkingArea
if ($f.Height -gt $wa.Height) { $f.AutoScroll = $true; $f.Height = $wa.Height }
[void]$f.ShowDialog()
Keep-Awake $false; Log-Close
try { $guiLock.ReleaseMutex() } catch { }
} catch {
    $m = "$($_.Exception.Message)"
    try { [IO.File]::WriteAllText((Join-Path $pkg 'setup-error.txt'), "AETHER AR Setup could not start: $m`r`n$($_.ScriptStackTrace)") } catch { }
    Say-Box "AETHER AR Setup could not start:`n`n$m`n`n(The details are in setup-error.txt next to ""Install AETHER AR.cmd"".)" 'Error'
    exit 1
}
