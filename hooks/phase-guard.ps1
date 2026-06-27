# phase-guard.ps1 - UserPromptSubmit hook enforcing phase transition gates.
$inputJson = [Console]::In.ReadToEnd()
try { $payload = $inputJson | ConvertFrom-Json } catch { exit 0 }
$prompt = if ($payload.PSObject.Properties.Name -contains 'prompt') { [string]$payload.prompt } else { '' }
$projectRoot = if ($env:SHAPEUP_PROJECT_DIR) { $env:SHAPEUP_PROJECT_DIR } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } elseif ($env:CODEX_WORKSPACE_ROOT) { $env:CODEX_WORKSPACE_ROOT } else { (Get-Location).Path }
$shapeupDir = Join-Path $projectRoot '.shapeup'
$hooksDir = $PSScriptRoot
$resolver = Join-Path $hooksDir 'lib/resolve-feature.ps1'
$command = ''; $key = ''
if ($prompt -match '^/(shapeup:)?shape\s+([^\s]+)') { $command = 'shape'; $key = $Matches[2] }
elseif ($prompt -match '^/(shapeup:)?build\s+([^\s]+)') { $command = 'build'; $key = $Matches[2] }
elseif ($prompt -match '^/(shapeup:)?ship\s+([^\s]+)') { $command = 'ship'; $key = $Matches[2] }
else { exit 0 }
if (-not (Test-Path -LiteralPath $shapeupDir -PathType Container)) { exit 0 }
if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) { exit 0 }
$errFile = [IO.Path]::GetTempFileName()
$resolved = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolver $shapeupDir $key 2> $errFile
$status = $LASTEXITCODE
if ($status -eq 2) { Get-Content -LiteralPath $errFile | ForEach-Object { [Console]::Error.WriteLine($_) }; Remove-Item -LiteralPath $errFile -Force; exit 2 }
Remove-Item -LiteralPath $errFile -Force
if ($status -ne 0 -or [string]::IsNullOrWhiteSpace($resolved)) { exit 0 }
$featureDir = [string]$resolved
switch ($command) {
  'shape' {
    $frame = Join-Path $featureDir 'frame.md'
    if (-not (Test-Path -LiteralPath $frame -PathType Leaf)) { [Console]::Error.WriteLine("Feature '$key' has no frame document. Run /frame first."); exit 2 }
    if ((Get-Content -LiteralPath $frame -Raw) -notmatch 'Frame Go') { [Console]::Error.WriteLine("Feature '$key' hasn't been approved for shaping. Run /frame to complete framing and get Frame Go approval."); exit 2 }
    if ($featureDir -match '-(shaped|building|shipped)$') { [Console]::Error.WriteLine("Feature '$key' is already shaped. Run /build $key to build it."); exit 2 }
  }
  'build' {
    if ($featureDir -match '-shipped$') { [Console]::Error.WriteLine("Feature '$key' is already shipped. To iterate, frame a new feature."); exit 2 }
    if (Test-Path -LiteralPath (Join-Path $featureDir 'build-summary.md') -PathType Leaf) { [Console]::Error.WriteLine("Build for feature '$key' is complete. Run /ship $key to archive and document decisions."); exit 2 }
    $package = Join-Path $featureDir 'package.md'
    if (-not (Test-Path -LiteralPath $package -PathType Leaf)) { [Console]::Error.WriteLine("Feature '$key' has no package. Run /shape $key first."); exit 2 }
    if ((Get-Content -LiteralPath $package -Raw) -notmatch 'Shape Go') { [Console]::Error.WriteLine("Feature '$key' hasn't been approved for building. Run /shape $key to complete shaping and get Shape Go approval."); exit 2 }
  }
  'ship' {
    if ($featureDir -match '-shipped$') { [Console]::Error.WriteLine("Feature '$key' is already shipped."); exit 2 }
    if (-not (Test-Path -LiteralPath (Join-Path $featureDir 'build-summary.md') -PathType Leaf)) { [Console]::Error.WriteLine("Feature '$key' hasn't completed building. Run /build $key first."); exit 2 }
  }
}
exit 0
