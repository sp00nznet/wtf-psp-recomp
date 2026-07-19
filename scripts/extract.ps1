<#
.SYNOPSIS
    Map a WTF: Work Time Fun disc image and pull out its executable modules.

.DESCRIPTION
    Runs the psprecomp toolkit over a dump you own: reports the disc identity
    and boot chain, extracts the main EBOOT plus the five game-sharing
    microgames, and prints each module's decryption requirements.

    Everything lands in work/, which is gitignored. No game data is ever
    committed to this repository.

.EXAMPLE
    .\scripts\extract.ps1 -Iso "WTF - Work Time Fun (USA).iso"

.EXAMPLE
    .\scripts\extract.ps1 -Iso D:\dumps\wtf.iso -OutDir D:\scratch\wtf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Iso,

    [string]$OutDir = "work",

    # Path to allegrexrecomp.exe. Defaults to the submodule build output.
    [string]$Tool
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path $Iso)) {
    throw "Disc image not found: $Iso"
}

# Locate the tool. Release first, then Debug, then a single-config generator's
# layout -- whichever the user actually built.
if (-not $Tool) {
    $candidates = @(
        "$repo\build\psprecomp\tools\allegrexrecomp\Release\allegrexrecomp.exe",
        "$repo\build\psprecomp\tools\allegrexrecomp\Debug\allegrexrecomp.exe",
        "$repo\build\psprecomp\tools\allegrexrecomp\allegrexrecomp.exe"
    )
    $Tool = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Tool -or -not (Test-Path $Tool)) {
    throw "allegrexrecomp not found. Build it first:`n" +
          "    cmake -S . -B build`n" +
          "    cmake --build build --config Release"
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$modules = Join-Path $OutDir "modules"
New-Item -ItemType Directory -Force $modules | Out-Null

Write-Host "`n=== Disc ===" -ForegroundColor Cyan
& $Tool info $Iso | Tee-Object -FilePath (Join-Path $OutDir "disc.txt")

Write-Host "`n=== Extracting executables ===" -ForegroundColor Cyan
# The main module and the five standalone game-sharing microgames. The
# extractor flattens ISO paths into filenames, so SYSDIR/EBOOT.BIN and
# SYSDIR/UPDATE/EBOOT.BIN do not collide.
& $Tool extract $Iso "EBOOT.BIN" $modules
& $Tool extract $Iso "bootbin"   $modules

# Pull one capture group out of the tool's report, tolerating its absence:
# a bare ~PSP module has no PARAM.SFO and therefore no TITLE, so a missing
# match is normal, not an error.
function Get-Field {
    param($Lines, [string]$Pattern, [string]$Default = "-")
    $m = $Lines | Select-String $Pattern | Select-Object -First 1
    if ($m -and $m.Matches.Count -gt 0 -and $m.Matches[0].Groups.Count -gt 1) {
        return $m.Matches[0].Groups[1].Value.Trim()
    }
    return $Default
}

Write-Host "`n=== Modules ===" -ForegroundColor Cyan
$report = Join-Path $OutDir "modules.txt"
$header = "{0,-46} {1,-24} {2,-12} {3,12} {4}" -f "file", "title", "module", "elf size", "key tag"
$header | Tee-Object -FilePath $report
("-" * 110) | Tee-Object -Append -FilePath $report

Get-ChildItem $modules -File | Sort-Object Name | ForEach-Object {
    $info = & $Tool info $_.FullName

    $title  = Get-Field $info '^\s+TITLE\s+(.+)$'
    $module = Get-Field $info '^\s+module\s+(\S+)\s*$'
    $tag    = Get-Field $info '^\s+tag\s+(\S+)\s*$'
    $elf    = Get-Field $info '^\s+elf size\s+(\d+)'

    "{0,-46} {1,-24} {2,-12} {3,12} {4}" -f $_.Name, $title, $module, $elf, $tag |
        Tee-Object -Append -FilePath $report
    $info | Set-Content (Join-Path $OutDir "$($_.BaseName).info.txt")
}

Write-Host "`nWrote $OutDir\disc.txt, $OutDir\modules.txt and per-module info." -ForegroundColor Green
Write-Host @"

Every executable module on this disc is encrypted (~PSP / KIRK). Decryption is
psprecomp phase 2 -- until it lands, `dis` and `cover` have nothing plaintext
to work on. See psprecomp/docs/DECRYPT.md.
"@ -ForegroundColor Yellow
