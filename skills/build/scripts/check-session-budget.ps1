# check-session-budget.ps1 - Deterministic session budget calculator
# Usage: check-session-budget.ps1 <feature-dir>
param([Parameter(Position=0)][string]$FeatureDir)

if ([string]::IsNullOrWhiteSpace($FeatureDir) -or -not (Test-Path -LiteralPath $FeatureDir -PathType Container)) {
  [Console]::Error.WriteLine('Usage: check-session-budget.ps1 <feature-dir>')
  exit 1
}

$handoverCount = @(Get-ChildItem -LiteralPath $FeatureDir -File -Filter 'handover-*.md' -ErrorAction SilentlyContinue).Count
$sessionsUsed = $handoverCount + 1
$package = Join-Path $FeatureDir 'package.md'
$appetiteRaw = if (Test-Path -LiteralPath $package -PathType Leaf) { (Select-String -LiteralPath $package -Pattern 'appetite' -CaseSensitive:$false | Select-Object -First 1).Line } else { '' }
if ($appetiteRaw -match '(?i)small') { $label = 'Small Batch'; $max = 1 }
elseif ($appetiteRaw -match '(?i)medium') { $label = 'Medium Batch'; $max = 3 }
elseif ($appetiteRaw -match '(?i)big') { $label = 'Big Batch'; $max = 5 }
else { $label = 'Unknown'; $max = 0 }
$scopes = Join-Path $FeatureDir 'scopes'
$nice = 0
$must = 0
if (Test-Path -LiteralPath $scopes -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $scopes -File -Filter '*.md' -ErrorAction SilentlyContinue) {
    foreach ($line in Get-Content -LiteralPath $file) {
      if ($line -match '- (\[ \]|\[RED\]) ~') { $nice++ }
      if ($line -match '- (\[ \]|\[RED\])' -and $line -notmatch '~') { $must++ }
    }
  }
}
$remaining = [Math]::Max($max - $sessionsUsed, 0)
Write-Output "sessions_used=$sessionsUsed"
Write-Output "appetite_label=$label"
Write-Output "appetite_max=$max"
Write-Output "sessions_remaining=$remaining"
Write-Output "nice_to_haves=$nice"
Write-Output "must_haves_remaining=$must"
