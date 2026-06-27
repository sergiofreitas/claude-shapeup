# setup-hooks.ps1 - point this clone's git at the tracked .githooks/ directory.
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) { exit 1 }
$hooksDir = Join-Path $repoRoot '.githooks'
if (-not (Test-Path -LiteralPath $hooksDir -PathType Container)) {
  [Console]::Error.WriteLine("setup-hooks.ps1: $hooksDir not found - are you in the right repo?")
  exit 1
}
& git -C $repoRoot config core.hooksPath .githooks
Write-Output 'Git hooks activated. core.hooksPath = .githooks'
Write-Output ''
Write-Output 'Installed hooks:'
Get-ChildItem -LiteralPath $hooksDir -File | ForEach-Object { Write-Output $_.Name }
Write-Output ''
Write-Output 'To bypass any hook on a specific commit: git commit --no-verify'
Write-Output 'Only do this when you know exactly why - see AGENTS.md and CLAUDE.md for the workflow.'
