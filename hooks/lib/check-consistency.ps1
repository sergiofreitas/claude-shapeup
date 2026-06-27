# check-consistency.ps1 - Audit a Shape Up feature folder for tracking drift.
# Usage: check-consistency.ps1 <feature-dir> [audit|strict|pre-ship]
param(
  [Parameter(Position=0)][string]$FeatureDir,
  [Parameter(Position=1)][string]$Mode = 'audit'
)

if ([string]::IsNullOrWhiteSpace($FeatureDir) -or -not (Test-Path -LiteralPath $FeatureDir -PathType Container)) {
  [Console]::Error.WriteLine('Usage: check-consistency.ps1 <feature-dir> [audit|strict|pre-ship]')
  exit 2
}

$script:Fails = 0
$script:Warns = 0
function Fail([string]$Message) { Write-Output "FAIL: $Message"; $script:Fails++ }
function Warn([string]$Message) { Write-Output "WARN: $Message"; $script:Warns++ }
function Note([string]$Message) { Write-Output "NOTE: $Message" }
function Read-Text([string]$Path) { if (Test-Path -LiteralPath $Path -PathType Leaf) { Get-Content -LiteralPath $Path -Raw } else { '' } }
function To-Kebab([string]$Value) { return (($Value.ToLowerInvariant() -replace '[^a-z0-9]+','-') -replace '^-|-$','') }

$ScopesDir = Join-Path $FeatureDir 'scopes'
$Hillchart = Join-Path $FeatureDir 'hillchart.md'
$Package = Join-Path $FeatureDir 'package.md'
$Frame = Join-Path $FeatureDir 'frame.md'

$scopeNames = @()
if (Test-Path -LiteralPath $ScopesDir -PathType Container) {
  $scopeNames = Get-ChildItem -LiteralPath $ScopesDir -File -Filter 'scope-*.md' -ErrorAction SilentlyContinue |
    ForEach-Object { $_.BaseName -replace '^scope-','' }
}

foreach ($name in $scopeNames) {
  $f = Join-Path $ScopesDir "scope-$name.md"
  $lines = Get-Content -LiteralPath $f -ErrorAction SilentlyContinue
  $unchecked = @($lines | Where-Object { $_ -match '^- (\[ \]|\[RED\])' -and $_ -notmatch '^- (\[ \]|\[RED\]) *~' })
  $position = ''
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## Hill Position') {
      if ($i + 1 -lt $lines.Count) { $position = ($lines[$i+1] -replace '[ \t]','') }
      break
    }
  }
  if ($position -match '✓' -and $unchecked.Count -gt 0) {
    Fail "scope '$name' claims ✓ Done but has $($unchecked.Count) RED must-have behavior(s) - flip to [GREEN] when observable, or cut with ~"
  }
  Note "scope '$name': unchecked_must_haves=$($unchecked.Count) position=$(if ($position) { $position } else { 'unknown' })"
}

$hillTildeNames = @()
if (Test-Path -LiteralPath $Hillchart -PathType Leaf) {
  $lines = Get-Content -LiteralPath $Hillchart
  $inScopes = $false
  $hillScopeNames = @()
  foreach ($line in $lines) {
    if ($line -match '^## Scopes') { $inScopes = $true; continue }
    if ($inScopes -and $line -match '^## ') { $inScopes = $false }
    if ($inScopes -and $line -match '^\s*[✓▼▲~]') {
      $entry = ($line -replace '^\s*[✓▼▲~]\s*','') -replace '\s*—.*$',''
      $hillScopeNames += $entry
      if ($line -match '^\s*~') { $hillTildeNames += $entry }
    }
  }
  foreach ($scopeName in $hillScopeNames) {
    if ([string]::IsNullOrWhiteSpace($scopeName)) { continue }
    $kebab = To-Kebab $scopeName
    $found = $false
    foreach ($sn in $scopeNames) {
      if ($sn -eq $kebab -or $sn.Contains($kebab) -or $kebab.Contains($sn)) { $found = $true; break }
    }
    if (-not $found) { Warn "hill chart lists scope '$scopeName' but no matching scope-*.md exists" }
  }
  $hillText = Read-Text $Hillchart
  foreach ($sn in $scopeNames) {
    if ($hillText -notmatch "(?i)(^|[^a-z])$([regex]::Escape($sn))([^a-z]|$)") {
      Warn "scope '$sn' has a file but is not mentioned in hillchart.md"
    }
  }
} elseif ($scopeNames.Count -gt 0) {
  Warn 'scopes exist but hillchart.md is missing'
}

function Scope-IsNiceToHave([string]$Kebab) {
  foreach ($tn in $hillTildeNames) {
    if ([string]::IsNullOrWhiteSpace($tn)) { continue }
    $tkebab = To-Kebab $tn
    if ($tkebab -eq $Kebab -or $tkebab.Contains($Kebab) -or $Kebab.Contains($tkebab)) { return $true }
  }
  return $false
}

if ($Mode -eq 'pre-ship') {
  if (-not (Test-Path -LiteralPath $Frame -PathType Leaf)) { Fail 'frame.md missing - cannot ship' }
  elseif ((Read-Text $Frame) -notmatch 'Frame Go') { Fail "frame.md lacks 'Frame Go' status" }

  if (-not (Test-Path -LiteralPath $Package -PathType Leaf)) { Fail 'package.md missing - cannot ship' }
  elseif ((Read-Text $Package) -notmatch 'Shape Go') { Fail "package.md lacks 'Shape Go' status" }

  if (Test-Path -LiteralPath $Hillchart -PathType Leaf) {
    $uphill = @((Get-Content -LiteralPath $Hillchart) | Where-Object { $_ -match '^\s*▲' }).Count
    if ($uphill -gt 0) { Fail "hillchart.md has $uphill scope(s) still ▲ Uphill - shaping gap, not ready to ship" }
  }

  foreach ($sn in $scopeNames) {
    $f = Join-Path $ScopesDir "scope-$sn.md"
    $unchecked = @((Get-Content -LiteralPath $f -ErrorAction SilentlyContinue) | Where-Object { $_ -match '^- (\[ \]|\[RED\])' -and $_ -notmatch '~' })
    if ($unchecked.Count -gt 0) {
      if (Scope-IsNiceToHave $sn) { Warn "nice-to-have scope '$sn' has $($unchecked.Count) RED must-have behavior(s) - acceptable (scope is cuttable); cut it explicitly or finish" }
      else { Fail "scope '$sn' has $($unchecked.Count) RED must-have behavior(s) - flip to [GREEN] when observable, or cut with ~" }
    }
  }
}

Write-Output "--- summary: FAIL=$script:Fails WARN=$script:Warns ---"
if ($Mode -ne 'audit' -and $script:Fails -gt 0) { exit 1 }
exit 0
