[CmdletBinding()]
param(
    [string]$SdkRoot = "$env:LOCALAPPDATA/Android/Sdk",
    [string]$JavaHome = 'C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot',
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $projectRoot 'out/android-emulator/back-gesture'
}
$javac = Join-Path $JavaHome 'bin/javac.exe'
$androidJar = Join-Path $SdkRoot 'platforms/android-36/android.jar'
$d8 = Join-Path $SdkRoot 'build-tools/36.0.0/d8.bat'
foreach ($required in @($javac, $androidJar, $d8)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing test tool: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$source = Join-Path $projectRoot 'tests/android/BackGesture.java'
& $javac --release 8 -Xlint:-options -cp $androidJar -d $OutputDirectory $source
if ($LASTEXITCODE -ne 0) { throw 'Gesture test helper compilation failed.' }
$previousJavaHome = $env:JAVA_HOME
try {
    $env:JAVA_HOME = $JavaHome
    $outputJar = Join-Path $OutputDirectory 'gesture.jar'
    & $d8 --lib $androidJar --min-api 28 --output $outputJar (Join-Path $OutputDirectory 'BackGesture.class')
    if ($LASTEXITCODE -ne 0) { throw 'Gesture test helper DEX conversion failed.' }
    Write-Output "Gesture helper: $outputJar"
} finally {
    $env:JAVA_HOME = $previousJavaHome
}
