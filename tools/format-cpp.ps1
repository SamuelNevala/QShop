[CmdletBinding()]
param(
    [string]$ClangFormat = 'C:/Qt/Tools/QtCreator/bin/clang/bin/clang-format.exe',
    [switch]$Check
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $ClangFormat -PathType Leaf)) {
    throw "clang-format not found: $ClangFormat"
}
$relativePaths = @(git -C $projectRoot ls-files -- '*.cpp' '*.h')
if ($LASTEXITCODE -ne 0 -or $relativePaths.Count -eq 0) {
    throw 'Cannot enumerate tracked C++ sources.'
}
$paths = @($relativePaths | ForEach-Object { Join-Path $projectRoot $_ })
$settings = Join-Path $projectRoot '.clang-format'
$arguments = @("--style=file:$settings", '--Werror', '--fail-on-incomplete-format')
if ($Check) {
    $arguments += @('--dry-run', '--ferror-limit=1')
} else {
    $arguments += '-i'
}
& $ClangFormat @arguments @paths
if ($LASTEXITCODE -ne 0) {
    throw 'clang-format failed; inspect the diagnostics above.'
}
if ($Check) {
    Write-Output "All $($paths.Count) tracked C++ files match .clang-format."
} else {
    Write-Output "Formatted $($paths.Count) tracked C++ files."
}
