# Publishes addons/godot-pixel-core from main to the addon-dist branch, then
# moves a consuming project's submodule to the new addon-dist commit.
#
# Usage (from anywhere):
#   powershell -File tools/publish-addon.ps1
#   powershell -File tools/publish-addon.ps1 -Consumer "D:\other\project" -NoConsumerCommit
param(
    [string]$Consumer = "G:\My Drive\project\gamedev\untombed\godot\untombed",
    [string]$SubmodulePath = "addons/godot-pixel-core",
    [switch]$NoConsumerCommit
)

$ErrorActionPreference = "Stop"
$Prefix = "addons/godot-pixel-core"
$DistBranch = "addon-dist"

function Invoke-Git {
    $out = & git @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed" }
    $out
}

$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
    if ((Invoke-Git rev-parse --abbrev-ref HEAD) -ne "main") { throw "Check out main before publishing." }
    if (Invoke-Git status --porcelain -- $Prefix) { throw "Uncommitted changes under $Prefix; commit them first." }

    Invoke-Git fetch origin --quiet
    Invoke-Git push origin main

    # Commit main's addon folder as the next addon-dist commit, keeping
    # addon-dist history linear so the push never needs --force.
    $mainSha = Invoke-Git rev-parse --short main
    $tree = Invoke-Git rev-parse "main:$Prefix"
    $parent = Invoke-Git rev-parse "origin/$DistBranch"
    if ((Invoke-Git rev-parse "$parent^{tree}") -eq $tree) {
        Write-Host "$DistBranch already matches main:$Prefix."
    } else {
        $dist = Invoke-Git commit-tree $tree -p $parent -m "Publish addon from main $mainSha"
        Invoke-Git push origin "${dist}:refs/heads/$DistBranch"
        Invoke-Git fetch origin --quiet
        Write-Host "Published $DistBranch at $($dist.Substring(0, 7)) (from main $mainSha)."
    }
} finally {
    Pop-Location
}

if (-not $Consumer) { return }

Push-Location $Consumer
try {
    Invoke-Git submodule update --init --remote -- $SubmodulePath
    Invoke-Git add -- $SubmodulePath
    if (-not (Invoke-Git diff --cached --name-only -- $SubmodulePath)) {
        Write-Host "Consumer submodule already up to date."
        return
    }
    & git rev-parse --verify --quiet HEAD *> $null
    $hasHistory = $LASTEXITCODE -eq 0
    if ($NoConsumerCommit -or -not $hasHistory) {
        Write-Host "Staged the submodule update in $Consumer (not committed)."
    } else {
        Invoke-Git commit -m "Update godot-pixel-core to main $mainSha" -- $SubmodulePath
        Write-Host "Committed the submodule update in $Consumer. Push it when ready."
    }
} finally {
    Pop-Location
}
