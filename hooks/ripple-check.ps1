# ripple-check.ps1 - PostToolUse hook for Shape Up document consistency.
$inputJson = [Console]::In.ReadToEnd()
try { $payload = $inputJson | ConvertFrom-Json } catch { exit 0 }
$filePath = if ($payload.tool_input -and ($payload.tool_input.PSObject.Properties.Name -contains 'file_path')) { [string]$payload.tool_input.file_path } else { '' }
if ($filePath -notmatch '\.shapeup[\\/].*\.md$') { exit 0 }
$basename = Split-Path -Leaf $filePath
$featureDir = Split-Path -Parent $filePath
$siblings = ''
if (Test-Path -LiteralPath $featureDir -PathType Container) {
  $siblings = ((Get-ChildItem -LiteralPath $featureDir -File -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object Name) -join ' ')
}
$hasScopes = if (Test-Path -LiteralPath (Join-Path $featureDir 'scopes') -PathType Container) { 'yes' } else { 'no' }
function ErrBlock([string]$Text) { [Console]::Error.WriteLine($Text.TrimEnd()) }
switch -Regex ($basename) {
  '^frame\.md$' { ErrBlock "RIPPLE CHECK - frame.md was modified.`nIf a package.md exists, verify: Does the package's Problem section still match the frame?`nIf requirements changed, the package's R table and fit check may need updating.`nSibling docs:$siblings" }
  '^package\.md$' { ErrBlock "RIPPLE CHECK - package.md was modified.`nIf scopes exist ($hasScopes), verify: Do scope must-haves still align with the package's elements?`nIf elements changed, verify the fit check matrix still has full R coverage.`nIf rabbit holes changed, check if any scope tasks reference resolved risks.`nSibling docs:$siblings" }
  '^hillchart\.md$' { ErrBlock "RIPPLE CHECK - hillchart.md was modified.`nVerify: Do scope file hill positions match the hillchart summary?`nIf a scope moved to done, check if its must-have tasks are all checked off.`nSibling docs:$siblings" }
  '^scope-.*\.md$' {
    $scopeName = $basename -replace '^scope-','' -replace '\.md$',''
    if ($scopeName -match '^(backend|frontend|database|api|ui|migrations?|infra|styling|testing|validation)(-|$)') {
      ErrBlock "SCOPE NAMING - scope '$scopeName' looks like a technical layer, not a business capability.`nScopes should describe what the customer can do when the scope is done.`nExample: instead of 'scope-api-endpoints', use 'scope-user-can-filter-invoices'."
    }
    ErrBlock "RIPPLE CHECK - scope file was modified: $basename`nVerify: Does hillchart.md reflect the current hill position of this scope?`nIf must-haves were added/removed, check if the package's fit check still holds.`nSibling docs:$siblings"
  }
  '^handover-.*\.md$' { exit 0 }
  default { ErrBlock "RIPPLE CHECK - $basename was modified in a Shape Up feature folder.`nConsider: Does this change affect frame.md, package.md, or any scope files?`nSibling docs:$siblings" }
}
exit 0
