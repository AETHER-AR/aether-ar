# Publishes an AETHER AR release ZIP in this repository, in one go:
#   1. package\ becomes exactly the ZIP's contents and NOTICE gets the version and today's date (one commit),
#   2. the tag v<version>,
#   3. a GitHub release with the ZIP attached. Its notes are the "## Version <version>" section of the package README.
#      It is marked as a pre-release (a tester build) unless -Final is given.
#
#   powershell -ExecutionPolicy Bypass -File tools\new-release.ps1 -Zip <...\AETHER-AR-1.0.14.zip> [-Final] [-NoPush]
#
# -NoPush stops after the commit and the tag (nothing leaves this PC). The ZIP is the one make-release.ps1 builds in
# the BT3-Recomp checkout; it has already been checked there (no game files, no developer notes).
param(
    [Parameter(Mandatory)][string]$Zip,
    [switch]$Final,
    [switch]$NoPush,
    [string]$CoAuthor = ''   # e.g. 'Claude Opus 5.5 <noreply@anthropic.com>' -> a Co-Authored-By line in the commit
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
function Git { & git -C $repo @args; if ($LASTEXITCODE) { throw "git $($args -join ' ') failed" } }

if (-not (Test-Path -LiteralPath $Zip)) { throw "no such ZIP: $Zip" }
$Zip = (Resolve-Path -LiteralPath $Zip).Path
$name = [IO.Path]::GetFileNameWithoutExtension($Zip)
if ($name -notmatch '^AETHER-AR-(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)$') { throw "not a release ZIP name: $name (expected AETHER-AR-<version>.zip)" }
$version = $matches[1]
$tag = "v$version"
if (& git -C $repo status --porcelain) { throw 'this repository has uncommitted changes -- commit or stash them first' }
if (& git -C $repo tag --list $tag) { throw "the tag $tag exists already" }

# 1. unpack the ZIP and check it is what make-release.ps1 builds
Add-Type -AssemblyName System.IO.Compression.FileSystem
$tmp = Join-Path $env:TEMP "aether-ar-release-$version"
if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
[IO.Compression.ZipFile]::ExtractToDirectory($Zip, $tmp)
$src = Join-Path $tmp $name
$baseFile = Join-Path $src 'mod\BASE'
if (-not (Test-Path $baseFile)) { throw "the ZIP has no $name\mod\BASE -- not a release package" }
$base = @{}; Get-Content $baseFile | ForEach-Object { if ($_ -match '^\s*(\w+)\s*=\s*(\S+)\s*$') { $base[$matches[1]] = $matches[2] } }
if ($base.version -ne $version) { throw "mod\BASE says version $($base.version), the ZIP's name says $version" }
$banned = Get-ChildItem -LiteralPath $src -Recurse -File | Where-Object { $_.Extension -in '.iso', '.bin', '.elf', '.exe', '.dll', '.ps2', '.mcd' -or $_.Name -in 'CLAUDE.md', 'project-notes.md' }
if ($banned) { throw "the ZIP holds files that never ship: $($banned.Name -join ', ')" }

# 2. package\ = the ZIP (the old files stay in git's history), LICENSE beside it, NOTICE's version line
if (Test-Path (Join-Path $repo 'package')) { Git rm -r -q package }
Copy-Item -LiteralPath $src -Destination (Join-Path $repo 'package') -Recurse
Copy-Item -LiteralPath (Join-Path $src 'LICENSE') -Destination (Join-Path $repo 'LICENSE') -Force
$notice = Join-Path $repo 'NOTICE'
$date = (Get-Date).ToString('d MMMM yyyy', [Globalization.CultureInfo]::GetCultureInfo('en-US'))
$text = [IO.File]::ReadAllText($notice)
$text = [regex]::Replace($text, '(?m)^Version \S+, .*$', "Version $version, $date")
$text = [regex]::Replace($text, 'based on commit [0-9a-f]{40}', "based on commit $($base.commit)")
[IO.File]::WriteAllText($notice, $text)
Git add -A
$msg = Join-Path $tmp 'commit.txt'
$body = "AETHER AR $version`n`nThe release package as published: mod commit $($base.mod), BT3-Recomp base $($base.commit).`n"
if ($CoAuthor) { $body += "`nCo-Authored-By: $CoAuthor`n" }
[IO.File]::WriteAllText($msg, $body)
Git commit -q -F $msg
Git tag -a $tag -m "AETHER AR $version"
"committed and tagged $tag"

# 3. the release notes: the README's section for this version, then how to install or update
$origin = (& git -C $repo remote get-url origin) -replace '\.git$', ''
if ($origin -notmatch 'github\.com[/:]([^/]+/[^/]+)$') { throw "the remote 'origin' is not a GitHub repository: $origin" }
$slug = $matches[1]
$readme = [IO.File]::ReadAllText((Join-Path $src 'README.md'))
$m = [regex]::Match($readme, "(?ms)^## Version $([regex]::Escape($version))\s*\r?\n(.*?)(?=^## )")
$changes = if ($m.Success) { $m.Groups[1].Value.Trim() } else { throw "package README has no '## Version $version' section -- write the changes there first" }
$notes = Join-Path $tmp 'notes.md'
[IO.File]::WriteAllText($notes, @"
$changes

**Install:** download ``$name.zip`` below, unpack it and double-click ``Install AETHER AR.cmd``. **Update:** the same -- Setup finds your install and keeps your memory card and settings (close AETHER AR first).

**Bring your own disc:** you need your own *Budokai Tenkaichi 3* (PS2, USA, SLUS-21678) as an ISO. Nothing of the game is included; never post or ask for disc images.

Something does not work? [Open an issue](https://github.com/$slug/issues/new/choose) and attach the ZIP from *Report a problem*.
"@)
if ($NoPush) { "-NoPush: nothing uploaded. Later: git push origin HEAD $tag, then gh release create $tag `"$Zip`" --notes-file `"$notes`""; return }

Git push -q origin HEAD $tag
$ghArgs = @('release', 'create', $tag, $Zip, '--title', "AETHER AR $version", '--notes-file', $notes, '--verify-tag')
if (-not $Final) { $ghArgs += '--prerelease' }
& gh -R $slug @ghArgs
if ($LASTEXITCODE) { throw 'gh release create failed (the commit and the tag are pushed; run it again by hand)' }
"released $tag" + $(if ($Final) { '' } else { ' (pre-release)' })
