[CmdletBinding()]
param(
    [string]$BuildDirectory = 'out/windows-agent',
    [string]$ReportDirectory = 'out/analysis',
    [string]$ClangTidy = 'C:/Qt/Tools/QtCreator/bin/clang/bin/clang-tidy.exe',
    [string]$Clazy = 'C:/Qt/Tools/QtCreator/bin/clang/bin/clazy-standalone.exe',
    [switch]$ApplicationOnly,
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
foreach ($tool in @($ClangTidy, $Clazy)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Analyzer not found: $tool"
    }
}
Push-Location $projectRoot
try {
    if (-not $SkipBuild) {
        if ($BuildDirectory -ne 'out/windows-agent') {
            throw 'Build a custom configuration first, then use -SkipBuild and -BuildDirectory.'
        }
        & "$PSScriptRoot/verify-windows.ps1" -Action Build
    }
    $buildPath = (Resolve-Path -LiteralPath $BuildDirectory).Path
    $database = Join-Path $buildPath 'compile_commands.json'
    if (-not (Test-Path -LiteralPath $database -PathType Leaf)) {
        throw 'Missing compile_commands.json. Configure with CMAKE_EXPORT_COMPILE_COMMANDS=ON and build generated headers first.'
    }
    $commands = Get-Content -LiteralPath $database -Raw | ConvertFrom-Json
    $sources = @(git ls-files -- '*.cpp')
    if ($LASTEXITCODE -ne 0 -or $sources.Count -eq 0) {
        throw 'Cannot enumerate tracked C++ sources.'
    }
    if ($ApplicationOnly) {
        $sources = @($sources | Where-Object { $_ -notlike 'tests/*' })
    }
    foreach ($source in $sources) {
        $sourcePath = (Join-Path $projectRoot $source).Replace('\', '/')
        if (-not ($commands | Where-Object { $_.file.Replace('\', '/') -eq $sourcePath })) {
            throw "Source missing from compilation database: $source"
        }
    }
    New-Item -ItemType Directory -Force -Path $ReportDirectory | Out-Null
    $reportPath = (Resolve-Path -LiteralPath $ReportDirectory).Path
    $clazyChecksFile = Join-Path $PSScriptRoot 'clazy-checks.txt'
    $clazyChecks = @(Get-Content -LiteralPath $clazyChecksFile | Where-Object {
        $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#')
    }) -join ','
    if (-not $clazyChecks) {
        throw 'No Clazy checks configured.'
    }
    Copy-Item -LiteralPath (Join-Path $projectRoot '.clang-tidy') -Destination (Join-Path $reportPath 'clang-tidy-config.yaml')
    Copy-Item -LiteralPath $clazyChecksFile -Destination (Join-Path $reportPath 'clazy-checks-config.txt')
    [pscustomobject]@{
        build_directory = $buildPath
        compilation_database_sha256 = (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash
        configuration = (Get-Content -LiteralPath (Join-Path $buildPath 'CMakeCache.txt') | Where-Object {
            $_ -match '^(CMAKE_(BUILD_TYPE|CXX_COMPILER|CXX_FLAGS)|ANDROID_ABI|BUILD_TESTING|QSHOPPER_DESKTOP_KEYBOARD)[:_]'
        })
        sources = $sources
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $reportPath 'build.json') -Encoding UTF8
    & $ClangTidy --verify-config
    if ($LASTEXITCODE -ne 0) {
        throw 'Invalid clang-tidy configuration.'
    }
    & $ClangTidy --version > (Join-Path $reportPath 'clang-tidy-version.txt')
    & $Clazy --version > (Join-Path $reportPath 'clazy-version.txt')
    & $ClangTidy --list-checks > (Join-Path $reportPath 'clang-tidy-checks.txt')
    & $Clazy "--checks=$clazyChecks" --list-checks > (Join-Path $reportPath 'clazy-checks.txt')
    $headerFilter = '(^|[/\\])(model|undoremove|weekmodel|sortfilterproxymodel)\.h$'
    $results = @()
    foreach ($source in $sources) {
        $stem = $source.Replace('/', '_').Replace('.cpp', '')
        foreach ($analyzer in @('tidy', 'clazy')) {
            $log = Join-Path $reportPath "$stem-$analyzer.txt"
            $fixes = Join-Path $reportPath "$stem-$analyzer.yaml"
            Remove-Item -LiteralPath $fixes -Force -ErrorAction SilentlyContinue
            Write-Output "Analyzing $source ($analyzer)"
            if ($analyzer -eq 'tidy') {
                & $ClangTidy -p $buildPath "--export-fixes=$fixes" $source *> $log
            } else {
                & $Clazy -p $buildPath "--checks=$clazyChecks" "--header-filter=$headerFilter" "--export-fixes=$fixes" $source *> $log
            }
            $exitCode = $LASTEXITCODE
            $diagnostics = @(Get-Content -LiteralPath $log | Where-Object {
                $_ -match ': (fatal error|warning|error): '
            })
            $results += [pscustomobject]@{
                source = $source
                analyzer = $analyzer
                exit_code = $exitCode
                diagnostics = $diagnostics
                passed = $exitCode -eq 0 -and $diagnostics.Count -eq 0
            }
        }
    }
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportPath 'results.json') -Encoding UTF8
    $failed = @($results | Where-Object { -not $_.passed })
    if ($failed.Count -gt 0) {
        throw "$($failed.Count) analyzer runs need review. See $reportPath/results.json and per-source logs. No fixes applied."
    }
    Write-Output "Both analyzers passed for all $($sources.Count) tracked C++ translation units. Reports: $reportPath"
} finally {
    Pop-Location
}
