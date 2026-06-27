# validate-package.ps1 - Check a package.md for unresolved items
# Usage: validate-package.ps1 <path-to-package.md>
param([Parameter(Position=0)][string]$Package)

if ([string]::IsNullOrWhiteSpace($Package) -or -not (Test-Path -LiteralPath $Package -PathType Leaf)) {
  [Console]::Error.WriteLine('Usage: validate-package.ps1 <path-to-package.md>')
  exit 1
}

$issues = 0
$text = Get-Content -LiteralPath $Package -Raw
$lines = Get-Content -LiteralPath $Package
if ($text -match '(?i)(^|[^a-zA-Z])(TBD|TODO|FIXME)([^a-zA-Z]|$)') {
  Write-Output 'UNRESOLVED ITEMS FOUND:'
  Select-String -LiteralPath $Package -Pattern '(^|[^a-zA-Z])(TBD|TODO|FIXME)([^a-zA-Z]|$)' -CaseSensitive:$false | ForEach-Object { Write-Output "$($_.LineNumber):$($_.Line)" }
  $issues++
}
$isSmall = $text -match 'Small Batch'
foreach ($section in @('## Problem','## Cost Tracking (USD)','## Rabbit Holes','## No-Gos')) {
  if ($text -notmatch [regex]::Escape($section)) { Write-Output "MISSING SECTION: $section"; $issues++ }
}
if ($isSmall) {
  foreach ($section in @('## Requirements','## Solution','## Technical Validation')) {
    if ($text -notmatch [regex]::Escape($section)) { Write-Output "MISSING SECTION: $section"; $issues++ }
  }
  if ($text -notmatch [regex]::Escape('### Changes') -and $text -notmatch '(?i)Fit check') {
    Write-Output 'WARNING: Small Batch package missing Changes table or inline Fit check'; $issues++
  }
} else {
  foreach ($section in @('## Appetite','## Requirements','## Solution','## Fit Check')) {
    if ($text -notmatch [regex]::Escape($section)) { Write-Output "MISSING SECTION: $section"; $issues++ }
  }
  if ($text -notmatch [regex]::Escape('### Element:')) { Write-Output 'WARNING: No solution elements defined (### Element:)'; $issues++ }
}
$costMatch = [regex]::Match($text, '(?ms)^## Cost Tracking \(USD\)\s*(.*?)(?=^## |\z)')
if ($costMatch.Success) {
  $costBlock = $costMatch.Groups[1].Value
  if ($costBlock -notmatch '(?i)Estimated') { Write-Output 'MISSING COST ESTIMATE: Cost Tracking (USD) must include Estimated'; $issues++ }
  elseif ($costBlock -notmatch '(?i)Estimated.*(\$[0-9]|Unknown)') { Write-Output 'INVALID COST ESTIMATE: Estimated must be a USD amount (e.g. $120) or Unknown with notes'; $issues++ }
}
if ($text -match '⚠️') {
  Write-Output 'UNRESOLVED FLAGGED UNKNOWNS (⚠️) FOUND:'
  Select-String -LiteralPath $Package -Pattern '⚠️' | ForEach-Object { Write-Output "$($_.LineNumber):$($_.Line)" }
  $issues++
}
if ($issues -eq 0) { Write-Output 'Package validation PASSED - all sections present, no unresolved items.'; exit 0 }
Write-Output ''
Write-Output "Package validation FAILED - $issues issue(s) found."
exit 1
