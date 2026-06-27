# regenerate-index.ps1 - Scan .shapeup/ and produce index.md dashboard.
# Usage: regenerate-index.ps1 <shapeup-dir>
param([Parameter(Position=0)][string]$ShapeupDir)

if ([string]::IsNullOrWhiteSpace($ShapeupDir) -or -not (Test-Path -LiteralPath $ShapeupDir -PathType Container)) {
  [Console]::Error.WriteLine('Usage: regenerate-index.ps1 <shapeup-dir>')
  exit 1
}

$index = Join-Path $ShapeupDir 'index.md'
$date = Get-Date -Format 'yyyy-MM-dd'
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Shape Up Project Dashboard')
[void]$sb.AppendLine()
[void]$sb.AppendLine("**Generated**: $date")
[void]$sb.AppendLine()

function Get-IdSlug([string]$Name, [string]$Status) {
  $stripped = $Name -replace "-$Status$", ''
  if ($stripped -match '^([0-9]{3})-(.+)$') { return @($Matches[1], $Matches[2]) }
  if ($stripped -match '^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)$') {
    $datePart = $Matches[1]
    $rest = $Matches[2]
    if ($rest -match '^(.+)-([0-9a-f]{4})$') { return @("$datePart-$($Matches[2])", $Matches[1]) }
    return @($datePart, $rest)
  }
  return @('', $stripped)
}
function Add-Section([string]$Title, [string]$Status, [array]$Dirs, [bool]$IncludeDecisions, [bool]$IncludeDiscard) {
  if (-not $Dirs -or $Dirs.Count -eq 0) { return }
  [void]$script:sb.AppendLine("## $Title")
  [void]$script:sb.AppendLine()
  foreach ($dir in $Dirs) {
    $name = Split-Path -Leaf $dir.FullName
    $pair = Get-IdSlug $name $Status
    [void]$script:sb.AppendLine("### $($pair[0]): $($pair[1])")
    $frame = Join-Path $dir.FullName 'frame.md'
    if ($Status -eq 'building' -and (Test-Path -LiteralPath $frame -PathType Leaf)) {
      $lines = Get-Content -LiteralPath $frame
      for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Problem') {
          $problem = if ($i + 2 -lt $lines.Count) { $lines[$i+2] } else { '' }
          if ($problem.Length -gt 200) { $problem = $problem.Substring(0,200) }
          [void]$script:sb.AppendLine("- **Problem**: $problem")
          break
        }
      }
    }
    if ($Status -eq 'building' -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'hillchart.md') -PathType Leaf)) { [void]$script:sb.AppendLine("- **Hill Chart**: See ``$name/hillchart.md``") }
    if ($IncludeDecisions -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'decisions.md') -PathType Leaf)) { [void]$script:sb.AppendLine("- Decisions: ``$name/decisions.md``") }
    if ($IncludeDiscard -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'discard-reason.md') -PathType Leaf)) { [void]$script:sb.AppendLine("- Reason: ``$name/discard-reason.md``") }
    [void]$script:sb.AppendLine()
  }
}
$dirs = Get-ChildItem -LiteralPath $ShapeupDir -Directory -ErrorAction SilentlyContinue
Add-Section 'Active - Building' 'building' @($dirs | Where-Object Name -like '*-building') $false $false
Add-Section 'Ready to Build - Shaped' 'shaped' @($dirs | Where-Object Name -like '*-shaped') $false $false
Add-Section 'In Progress - Framing' 'framing' @($dirs | Where-Object Name -like '*-framing') $false $false
Add-Section 'Completed - Shipped' 'shipped' @($dirs | Where-Object Name -like '*-shipped') $true $false
Add-Section 'Discarded' 'discarded' @($dirs | Where-Object Name -like '*-discarded') $false $true
Set-Content -LiteralPath $index -Value $sb.ToString() -Encoding UTF8
Write-Output "Dashboard regenerated at $index"
