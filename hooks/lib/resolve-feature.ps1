# resolve-feature.ps1 - Resolve a feature key to an on-disk folder path.
# Usage: resolve-feature.ps1 <shapeup-dir> <key>
param(
  [Parameter(Position=0)][string]$ShapeupDir,
  [Parameter(Position=1)][string]$Key
)

$Statuses = @('framing','shaped','building','shipped','discarded')

if ([string]::IsNullOrWhiteSpace($ShapeupDir) -or [string]::IsNullOrWhiteSpace($Key)) {
  [Console]::Error.WriteLine('Usage: resolve-feature.ps1 <shapeup-dir> <key>')
  exit 1
}
if (-not (Test-Path -LiteralPath $ShapeupDir -PathType Container)) { exit 1 }

function Join-FeaturePath([string]$Base) {
  $out = @()
  foreach ($status in $Statuses) {
    $candidate = Join-Path $ShapeupDir "$Base-$status"
    if (Test-Path -LiteralPath $candidate -PathType Container) { $out += (Resolve-Path -LiteralPath $candidate).Path }
  }
  return $out
}

$matches = @()

if ($Key -match '^[0-9]+$') {
  $padded = ([int]$Key).ToString('000')
  $matches = Get-ChildItem -LiteralPath $ShapeupDir -Directory -Filter "$padded-*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
}

if ($matches.Count -eq 0 -and $Key -match '^[0-9]{4}-[0-9]{2}-[0-9]{2}-') {
  $matches = @(Join-FeaturePath $Key)
}

if ($matches.Count -eq 0) {
  foreach ($dir in Get-ChildItem -LiteralPath $ShapeupDir -Directory -ErrorAction SilentlyContinue) {
    $name = $dir.Name
    $stripped = $name -replace '^[0-9]{4}-[0-9]{2}-[0-9]{2}-','' -replace '^[0-9]{3}-',''
    $slugPart = $null
    foreach ($status in $Statuses) {
      if ($stripped.EndsWith("-$status")) {
        $slugPart = $stripped.Substring(0, $stripped.Length - $status.Length - 1)
        break
      }
    }
    if ([string]::IsNullOrEmpty($slugPart)) { continue }
    $slugBase = $slugPart -replace '-[0-9a-f]{4}$',''
    if ($slugPart -eq $Key -or $slugBase -eq $Key) { $matches += $dir.FullName }
  }
}

$matches = @($matches | Where-Object { $_ } | Sort-Object -Unique)
if ($matches.Count -eq 0) { exit 1 }
if ($matches.Count -gt 1) {
  [Console]::Error.WriteLine("resolve-feature.ps1: key '$Key' is ambiguous, matches multiple features:")
  foreach ($m in $matches) { [Console]::Error.WriteLine($m) }
  [Console]::Error.WriteLine('Use the full date-slug key (including any -<hex> disambiguator) to select one.')
  exit 2
}
Write-Output $matches[0].TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
