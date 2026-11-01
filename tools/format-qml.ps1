[CmdletBinding()]
param(
    [string]$QtRoot = 'C:/Qt/6.12.0/msvc2022_64',
    [switch]$Check
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$formatter = Join-Path $QtRoot 'bin/qmlformat.exe'
$settings = Join-Path $projectRoot '.qmlformat.ini'
if (-not (Test-Path -LiteralPath $formatter -PathType Leaf)) {
    throw "qmlformat not found: $formatter"
}
$relativePaths = @(git -C $projectRoot ls-files -- '*.qml' '*.qml.in')
if ($LASTEXITCODE -ne 0 -or $relativePaths.Count -eq 0) {
    throw 'Cannot enumerate tracked QML sources.'
}
$paths = @($relativePaths | ForEach-Object { Join-Path $projectRoot $_ })
$savedDialogs = $env:QT_COMMAND_LINE_PARSER_NO_GUI_MESSAGE_BOXES
$savedLogging = $env:QT_FORCE_STDERR_LOGGING
try {
    $env:QT_COMMAND_LINE_PARSER_NO_GUI_MESSAGE_BOXES = '1'
    $env:QT_FORCE_STDERR_LOGGING = '1'
    $changed = @()
    foreach ($path in $paths) {
        $inputPath = $path
        $temporary = $null
        if ($path.EndsWith('.qml.in')) {
            # qmlformat requires a .qml suffix. Stage outside the checkout so
            # deployment scans cannot discover the optional keyboard imports.
            $temporary = Join-Path ([System.IO.Path]::GetTempPath()) ("qshopper-format-$([guid]::NewGuid().ToString('N')).qml")
            [System.IO.File]::Copy($path, $temporary)
            $inputPath = $temporary
        }
        try {
            if ($Check) {
                $output = @(& $formatter --settings $settings $inputPath)
                if ($LASTEXITCODE -ne 0) { throw "qmlformat failed: $path" }
                $formatted = ($output -join "`n") + "`n"
                if ([System.IO.File]::ReadAllText($path) -cne $formatted) {
                    $changed += $path
                    Write-Output "Needs formatting: $path"
                }
            } else {
                & $formatter --settings $settings --inplace $inputPath
                if ($LASTEXITCODE -ne 0) { throw "qmlformat failed: $path" }
                if ($temporary) { [System.IO.File]::Copy($temporary, $path, $true) }
            }
        } finally {
            if ($temporary) { [System.IO.File]::Delete($temporary) }
        }
    }
    if ($Check) {
        if ($changed.Count) { throw "$($changed.Count) QML files need formatting." }
        Write-Output "All $($paths.Count) tracked QML files match .qmlformat.ini."
    } else {
        Write-Output "Formatted $($paths.Count) tracked QML files."
    }
} finally {
    $env:QT_COMMAND_LINE_PARSER_NO_GUI_MESSAGE_BOXES = $savedDialogs
    $env:QT_FORCE_STDERR_LOGGING = $savedLogging
}
