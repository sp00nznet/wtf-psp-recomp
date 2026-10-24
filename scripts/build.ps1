<#
.SYNOPSIS
    Recompile the WTF microgames you have decrypted and build them.

.DESCRIPTION
    For every work\dec\<id>.elf, generates C with allegrexrecomp into
    build\gen\<id>\ and builds build\games\wtf\Release\wtf_<id>.exe. Nothing
    generated is committed: it is derived from your own copy of the game.

.EXAMPLE
    .\scripts\build.ps1
    .\build\games\wtf\Release\wtf_b04_pendemonium.exe
#>
param(
    # Decrypted modules, named <id>.elf (b02_lumberjack.elf, b04_pendemonium.elf, ...).
    [string]$DecDir = "",
    # A psprecomp working copy to build against instead of the submodule.
    [string]$Psprecomp = ""
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
if (-not $DecDir) { $DecDir = Join-Path $repo "work\dec" }
$build = Join-Path $repo "build"

$cfg = @("-S", $repo, "-B", $build, "-DWTF_DEC_DIR=$DecDir")
if ($Psprecomp) { $cfg += "-DPSPRECOMP_DIR=$Psprecomp" }

Write-Host "=== Configure, build the recompiler ===" -ForegroundColor Cyan
cmake @cfg | Out-Null
if ($LASTEXITCODE) { throw "configure failed" }
cmake --build $build --config Release --target allegrexrecomp
if ($LASTEXITCODE) { throw "allegrexrecomp failed to build" }
$tool = Get-ChildItem (Join-Path $build "psprecomp\tools\allegrexrecomp") -Recurse -Filter allegrexrecomp.exe |
    Select-Object -First 1
if (-not $tool) { throw "allegrexrecomp.exe not found under $build" }

$elves = Get-ChildItem $DecDir -Filter "b*.elf" -ErrorAction SilentlyContinue
if (-not $elves) { throw "no decrypted microgames in $DecDir (expected b02_lumberjack.elf etc.)" }

Write-Host "`n=== Recompile ===" -ForegroundColor Cyan
foreach ($e in $elves) {
    $id = $e.BaseName
    $gen = Join-Path $build "gen\$id"
    New-Item -ItemType Directory -Force $gen | Out-Null
    & $tool.FullName emit $e.FullName $gen $id | Select-Object -Last 2
    if ($LASTEXITCODE) { throw "emit failed for $id" }
}

Write-Host "`n=== Build the games ===" -ForegroundColor Cyan
cmake @cfg | Out-Null                       # pick up the generated sources
cmake --build $build --config Release
if ($LASTEXITCODE) { throw "build failed" }

Write-Host "`nBuilt:" -ForegroundColor Green
Get-ChildItem (Join-Path $build "games\wtf") -Recurse -Filter "wtf_*.exe" | ForEach-Object { "  $($_.FullName)" }
