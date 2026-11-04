# AETHER AR -- is this ISO the original USA disc of Budokai Tenkaichi 3 (SLUS-21678)? Throws a plain message that says
# what to do when it is not. Shared by ar\install.ps1 and the release installer, which runs it from the package's
# setup\ folder before git and the build: a wrong disc was found only after the whole toolchain was installed (release
# audit 31.10.).
#   check-iso.ps1 -Iso <iso> -Work <folder for the check, removed afterwards; not %TEMP%, which can be a path tar cannot use>
param([string]$Iso, [string]$Work)
$ErrorActionPreference = 'Stop'
# -LiteralPath: "Dragon Ball Z [SLUS-21678].iso" is a file name, not a wildcard; .ProviderPath: a \\NAS\ path without
# PowerShell's "FileSystem::" prefix, which tar cannot open
$Iso = "$Iso".Trim().Trim('"').Trim()   # (Windows' "Copy as path" pastes it in quotes)
if (-not $Iso -or -not (Test-Path -LiteralPath $Iso -PathType Leaf)) { throw "ISO not found: $Iso" }
$Iso = (Resolve-Path -LiteralPath $Iso).ProviderPath
# only a *.iso: the build (setup.py) takes anything else for a bare game file, and failed 30+ minutes later with a
# misleading hash message (31.10.)
$ext = [IO.Path]::GetExtension($Iso).ToLowerInvariant(); $name = [IO.Path]::GetFileName($Iso)
if ($ext -ne '.iso') {
    if ($ext -in '.zip', '.7z', '.rar', '.gz', '.xz', '.bz2', '.zst', '.lz4', '.tar', '.tgz') { throw "the disc image is packed ('$name') -- unpack it first, then pick the .iso inside" }
    if ($ext -in '.chd', '.cso', '.zso', '.cue') { throw "'$name' is not a plain PS2 .iso (CHD / CSO / BIN+CUE do not work) -- convert it to .iso first, then run this again" }
    throw "the disc image has to end in .iso -- rename '$name' so it ends in .iso (if it is a plain PS2 disc image), then run this again"
}
# a plain ISO 9660 image has 'CD001' at byte 0x8001: tar would also read a packed image renamed to .iso, which the game
# cannot (review 31.10.)
$fs = [IO.File]::OpenRead($Iso)
try { $sig = New-Object byte[] 5; $null = $fs.Seek(0x8001, 'Begin'); $got = $fs.Read($sig, 0, 5) } finally { $fs.Dispose() }
if ($got -ne 5 -or [Text.Encoding]::ASCII.GetString($sig) -ne 'CD001') { throw "'$name' is not a plain PS2 .iso (packed or converted?) -- unpack / convert it to a plain .iso first, then run this again" }
if (-not $Work) { throw "check-iso.ps1 needs -Work (a folder for the check)" }
$tar = "$env:SystemRoot\System32\tar.exe"
if (-not (Test-Path -LiteralPath $tar)) { throw "Windows' tar.exe is missing -- Windows 10 version 1803 or newer is needed" }

Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $Work | Out-Null
try {
    # tar's notes on stderr are no error here (see Run-Winget in install.ps1): its exit code and its words decide
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = @(& $tar -tf $Iso 2>&1); $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    $list = @($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    $err = (@($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }) -join ' ').Trim()
    # tar opens files by their ANSI name: a path with characters outside it (e.g. Japanese in a Western Windows) comes
    # back as "Failed to open '...??...'" -- that is the path, not the disc. ("Error opening archive: Unrecognized
    # archive format" is tar reading a file that is no ISO, so 'Error opening' alone says nothing.)
    if ($code -ne 0 -and $err -match 'Failed to open|Can.t open') { throw "Windows' tar cannot open the ISO at this path ($Iso) -- move it to a plain folder such as C:\ISO\bt3.iso and run this again" }
    if ($code -ne 0 -or -not $list.Count) { throw "'$Iso' is not a plain PS2 .iso (CHD / CSO / BIN+CUE do not work) -- convert it to .iso first, then run this again" }
    if ($list -notcontains 'SLUS_216.78') {
        $id = $list | Where-Object { $_ -match '^(SLES|SCES|SLPS|SLPM|SCPS|SLKA|SLUS)_\d{3}\.\d{2}' } | Select-Object -First 1
        throw "this disc is $(if ($id) { $id } else { 'not Budokai Tenkaichi 3' }) -- only the USA release of Budokai Tenkaichi 3 (SLUS-21678) works. Pick that ISO and run this again"
    }
    if ($list -notcontains 'BIN/DBZP.BIN') { throw "BIN/DBZP.BIN is missing from this ISO -- the image is incomplete; use a clean dump of the USA disc" }
    # the game file out into the work folder, as tar's current folder (no -C: tar would take that path by its ANSI
    # name too)
    Push-Location -LiteralPath $Work
    try {
        $ErrorActionPreference = 'Continue'
        $xout = @(& $tar -xf $Iso SLUS_216.78 2>&1)
        $ErrorActionPreference = $old
    } finally { Pop-Location }
    $elf = Join-Path $Work 'SLUS_216.78'
    if (-not (Test-Path -LiteralPath $elf -PathType Leaf)) {
        $why = (@($xout | ForEach-Object { "$_" }) -join ' ').Trim()
        throw "the game file could not be taken out of the ISO for the check$(if ($why) { " ($why)" }) -- make sure the drive of $Work has free space and your antivirus does not block it, then run this again"
    }
    $h = (Get-FileHash -LiteralPath $elf -Algorithm SHA256).Hash
    if ($h -ne '811188BA9B416500D921CD4D9514DF0CBF42F3A41A99CF5AAC5A3DA37171BF99') { throw "this USA ISO's game file differs from the original release (a modded or bad dump) -- use a clean dump of SLUS-21678" }
} finally {
    Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
}
