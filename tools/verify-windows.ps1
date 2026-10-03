[CmdletBinding()]
param(
    [ValidateSet('Verify', 'Build', 'Test')][string]$Action = 'Verify',
    [string]$QtRoot = 'C:/Qt/6.12.0/msvc2022_64',
    [string]$CMakeBin = 'C:/Qt/Tools/CMake_64/bin',
    [string]$Ninja = 'C:/Qt/Tools/Ninja/ninja.exe',
    [ValidateRange(1, 64)][int]$Jobs = 4
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$cmake = Join-Path $CMakeBin 'cmake.exe'
$ctest = Join-Path $CMakeBin 'ctest.exe'
foreach ($required in @($cmake, $ctest, $Ninja, (Join-Path $QtRoot 'lib/cmake/Qt6/Qt6Config.cmake'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Required tool or Qt kit missing: $required" }
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Install Visual Studio C++ tools or use Developer PowerShell.' }
    $vsPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vsPath) { throw 'No Visual Studio installation with x64 C++ tools was found.' }
    Import-Module (Join-Path $vsPath 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll')
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
}
$savedQt = $env:QSHOPPER_QT_ROOT
$savedNinja = $env:QSHOPPER_NINJA
Push-Location $projectRoot
try {
    $env:QSHOPPER_QT_ROOT = $QtRoot
    $env:QSHOPPER_NINJA = $Ninja
    if ($Action -ne 'Test') {
        & $cmake --preset windows-agent
        if ($LASTEXITCODE -ne 0) { throw "Configure failed: $LASTEXITCODE" }
        & $cmake --build --preset windows-agent --parallel $Jobs
        if ($LASTEXITCODE -ne 0) { throw "Build failed: $LASTEXITCODE" }
    }
    if ($Action -ne 'Build') {
        & $ctest --preset windows-agent
        if ($LASTEXITCODE -ne 0) { throw "Tests failed: $LASTEXITCODE" }
    }
} finally {
    $env:QSHOPPER_QT_ROOT = $savedQt
    $env:QSHOPPER_NINJA = $savedNinja
    Pop-Location
}
