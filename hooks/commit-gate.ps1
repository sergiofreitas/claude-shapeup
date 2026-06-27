# commit-gate.ps1 - PreToolUse hook. Intercepts git commit invocations.
$inputJson = [Console]::In.ReadToEnd()
try { $payload = $inputJson | ConvertFrom-Json } catch { exit 0 }
$toolName = if ($payload.PSObject.Properties.Name -contains 'tool_name') { [string]$payload.tool_name } else { '' }
$command = if ($payload.tool_input -and ($payload.tool_input.PSObject.Properties.Name -contains 'command')) { [string]$payload.tool_input.command } else { '' }
if ($toolName -ne 'Bash' -and $toolName -ne 'PowerShell') { exit 0 }
if ($command -notmatch '(^|[\s;]|&&|\|\|)git\s+commit(\s|$)') { exit 0 }
$projectRoot = if ($env:SHAPEUP_PROJECT_DIR) { $env:SHAPEUP_PROJECT_DIR } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } elseif ($env:CODEX_WORKSPACE_ROOT) { $env:CODEX_WORKSPACE_ROOT } else { (Get-Location).Path }
$gate = Join-Path $PSScriptRoot 'lib/commit-gate.ps1'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) { [Console]::Error.WriteLine("commit-gate: gate library not found at $gate; passing through."); exit 0 }
& powershell -NoProfile -ExecutionPolicy Bypass -File $gate $projectRoot
if ($LASTEXITCODE -ne 0) { exit 2 }
exit 0
