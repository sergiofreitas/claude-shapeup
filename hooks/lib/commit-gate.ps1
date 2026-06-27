# commit-gate.ps1 - Pre-commit consistency gate for .shapeup/ tracking docs.
# Usage: commit-gate.ps1 <project-root>
param([Parameter(Position=0)][string]$ProjectRoot)
if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or -not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  $displayRoot = if ($ProjectRoot) { $ProjectRoot } else { '<empty>' }
  [Console]::Error.WriteLine("commit-gate: project root not found: $displayRoot")
  exit 2
}
$checker = Join-Path $PSScriptRoot 'check-consistency.ps1'
if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) { [Console]::Error.WriteLine("commit-gate: check-consistency.ps1 missing at $checker"); exit 2 }
Push-Location $ProjectRoot
try {
  & git rev-parse --git-dir *> $null
  if ($LASTEXITCODE -ne 0) { exit 0 }
  $staged = & git diff --cached --name-only 2>$null
  $featureDirs = @($staged | Where-Object { $_ -match '^\.shapeup/[^/]+/' } | ForEach-Object { ($_ -replace '^(\.shapeup/[^/]+)/.*','$1') } | Sort-Object -Unique)
  if ($featureDirs.Count -eq 0) { exit 0 }
  $failed = $false
  $report = New-Object System.Text.StringBuilder
  foreach ($rel in $featureDirs) {
    $full = Join-Path $ProjectRoot $rel
    if (-not (Test-Path -LiteralPath $full -PathType Container)) { continue }
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $checker $full audit 2>&1
    $findings = @($out | Where-Object { $_ -match '^(FAIL|WARN):' })
    if ($findings.Count -gt 0) {
      $failed = $true
      [void]$report.AppendLine("`n--- $rel ---")
      foreach ($f in $findings) { [void]$report.AppendLine($f) }
    }
  }
  if ($failed) {
    [Console]::Error.WriteLine(@"
commit-gate: .shapeup/ tracking docs disagree with the staged diff.

Each scope-completion commit must bundle code + the scope file + hillchart.md
so the next session starts from a coherent state. Fix the findings below,
re-stage, and try again.
$report
Typical fixes:
  - Scope claims ✓ Done but has unchecked must-haves -> tick the boxes, cut with ~,
    or revert the hill position.
  - hillchart.md lists a scope that has no scope-*.md file -> remove the entry
    or add the missing scope file.
  - Scope file exists but not in hillchart.md -> add it with its current symbol.

Do NOT bypass with --no-verify unless the drift is genuinely irrelevant to
what you're committing (and document why).
"@)
    exit 1
  }
  exit 0
} finally { Pop-Location }
