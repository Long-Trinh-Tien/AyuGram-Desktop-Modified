# Build nhanh cho agent (PowerShell) — dung khi solution da configure
# Usage: powershell -ExecutionPolicy Bypass -File tools/win/agent-build.ps1 [-Config Release]
param([string]$Config = "Release")
$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$work = Join-Path $repo "Telegram"
$out  = Join-Path $repo "out"
$log  = Join-Path $work "build_output.log"  # da gitignore
& cmake --build $out --config $Config --target Telegram *> $log
if ($LASTEXITCODE -eq 0) { Write-Output "BUILD_SUCCESS -> $log" } else { Write-Output "BUILD_FAILED -> $log"; exit 1 }
