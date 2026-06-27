# update-hillchart.ps1 - Initialize or display hill chart template
# Usage: update-hillchart.ps1 <hillchart-path> <init|show>
param(
  [Parameter(Position=0)][string]$Hillchart,
  [Parameter(Position=1)][string]$Action
)

if ([string]::IsNullOrWhiteSpace($Hillchart) -or [string]::IsNullOrWhiteSpace($Action)) {
  [Console]::Error.WriteLine('Usage: update-hillchart.ps1 <hillchart-path> <init|show>')
  exit 1
}

switch ($Action) {
  'init' {
    $date = Get-Date -Format 'yyyy-MM-dd'
    $content = @"
# Hill Chart
**Updated**: $date
**Session**: 01

## Scopes
  ▲ (first scope will be discovered through work)

## Risk
(to be determined after orientation)

## Next
(pick first piece: core + small + novel)
"@
    Set-Content -LiteralPath $Hillchart -Value $content -Encoding UTF8
    Write-Output "Hill chart initialized at $Hillchart"
  }
  'show' {
    if (Test-Path -LiteralPath $Hillchart -PathType Leaf) { Get-Content -LiteralPath $Hillchart }
    else { [Console]::Error.WriteLine("No hill chart found at $Hillchart"); exit 1 }
  }
  default { [Console]::Error.WriteLine("Unknown action: $Action. Use 'init' or 'show'."); exit 1 }
}
