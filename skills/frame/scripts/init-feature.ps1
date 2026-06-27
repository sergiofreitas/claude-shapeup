# init-feature.ps1 - Create a new date-slug feature folder in .shapeup/
# Usage: init-feature.ps1 <shapeup-dir> <slug> [YYYY-MM-DD]
param(
  [Parameter(Position=0)][string]$ShapeupDir,
  [Parameter(Position=1)][string]$Slug,
  [Parameter(Position=2)][string]$DateOverride
)

if ([string]::IsNullOrWhiteSpace($ShapeupDir) -or [string]::IsNullOrWhiteSpace($Slug)) {
  [Console]::Error.WriteLine('Usage: init-feature.ps1 <shapeup-dir> <slug> [YYYY-MM-DD]')
  exit 1
}

$slugNormalized = (($Slug.ToLowerInvariant() -replace '[^a-z0-9-]+','-') -replace '-+','-') -replace '^-|-$',''
if ([string]::IsNullOrWhiteSpace($slugNormalized)) {
  [Console]::Error.WriteLine('init-feature.ps1: slug normalized to empty string - provide alphanumerics')
  exit 1
}

$date = if ($DateOverride) { $DateOverride } else { Get-Date -Format 'yyyy-MM-dd' }
New-Item -ItemType Directory -Force -Path $ShapeupDir | Out-Null
$baseKey = "$date-$slugNormalized"
$existing = Get-ChildItem -LiteralPath $ShapeupDir -Directory -Filter "$baseKey-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existing) {
  $bytes = New-Object byte[] 2
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
  $hex = ([BitConverter]::ToString($bytes) -replace '-','').ToLowerInvariant()
  $baseKey = "$date-$slugNormalized-$hex"
}
$folderPath = Join-Path $ShapeupDir "$baseKey-framing"
New-Item -ItemType Directory -Force -Path $folderPath | Out-Null
Write-Output $folderPath
