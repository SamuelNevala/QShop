param(
    [string]$QtRoot = 'C:\Qt',
    [string]$QtVersion = '6.12.0',
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$NdkVersion = '27.2.12479018',
    [string]$JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot',
    [ValidateSet('arm64', 'x86_64')][string]$Architecture = 'arm64',
    [string]$DebugKeystore = '',
    [switch]$VerifyPackage,
    [switch]$QmlDebug,
    [string]$Python = 'python',
    [ValidateRange(1, 64)][int]$Jobs = 4
)

$ErrorActionPreference = 'Stop'
$buildFolder = if ($Architecture -eq 'arm64') { 'build-android-arm64' } else { 'out/android-emulator-build' }
$buildDir = Join-Path $PSScriptRoot $buildFolder
$appBuildDir = Join-Path $buildDir 'app'
$qtKit = if ($Architecture -eq 'arm64') { 'android_arm64_v8a' } else { 'android_x86_64' }
$qtCmake = Join-Path $QtRoot "$QtVersion\$qtKit\bin\qt-cmake.bat"
$cmake = Join-Path $QtRoot 'Tools\CMake_64\bin\cmake.exe'
$ninja = Join-Path $QtRoot 'Tools\Ninja\ninja.exe'
$hostQt = Join-Path $QtRoot "$QtVersion\msvc2022_64"
$ndk = Join-Path $SdkRoot "ndk\$NdkVersion"
foreach ($path in @($qtCmake, $cmake, $ninja, $hostQt, $SdkRoot, $ndk, "$JavaHome\bin\java.exe")) {
    if (!(Test-Path -LiteralPath $path)) { throw "Missing build prerequisite: $path" }
}
if ($DebugKeystore) {
    if (!(Test-Path -LiteralPath $DebugKeystore -PathType Leaf)) {
        throw "Debug keystore not found: $DebugKeystore"
    }
    $DebugKeystore = (Resolve-Path -LiteralPath $DebugKeystore).Path
}

$previousJavaHome = $env:JAVA_HOME
try {
    $env:JAVA_HOME = $JavaHome
    $qmlDebugSetting = if ($QmlDebug) { 'ON' } else { 'OFF' }
    & $qtCmake -S $PSScriptRoot -B $buildDir -G Ninja `
        "-DCMAKE_MAKE_PROGRAM=$ninja" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=OFF `
        "-DQT_HOST_PATH=$hostQt" "-DANDROID_SDK_ROOT=$SdkRoot" "-DANDROID_NDK_ROOT=$ndk" `
        "-DQT_ENABLE_QML_DEBUG=$qmlDebugSetting"
    if ($LASTEXITCODE -ne 0) { throw 'Android CMake configuration failed.' }
    # OneDrive can mark generated directories read-only, preventing Gradle
    # from replacing native libraries during an incremental build.
    $gradleBuildDir = Join-Path $appBuildDir 'android-build\build'
    if (Test-Path -LiteralPath $gradleBuildDir) {
        $generatedItems = @(Get-Item -LiteralPath $gradleBuildDir) +
            @(Get-ChildItem -LiteralPath $gradleBuildDir -Recurse -Force)
        foreach ($item in $generatedItems) {
            if ($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
    }
    & $cmake --build $buildDir --target apk --parallel $Jobs
    if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }

    $apk = Get-ChildItem "$appBuildDir\android-build" -Recurse -Filter '*-debug.apk' |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (!$apk) { throw 'Build completed but no debug APK was found.' }
    $outputDir = Join-Path $PSScriptRoot 'dist'
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    $outputApk = Join-Path $outputDir "QShopper-$Architecture-debug.apk"
    if ($DebugKeystore) {
        $deployment = Get-Content -Raw (Join-Path $appBuildDir 'android-application-deployment-settings.json') |
            ConvertFrom-Json
        $apkSigner = Join-Path $SdkRoot "build-tools/$($deployment.sdkBuildToolsRevision)/apksigner.bat"
        if (!(Test-Path -LiteralPath $apkSigner)) { throw "APK signer not found: $apkSigner" }
        & $apkSigner sign --ks $DebugKeystore --ks-key-alias androiddebugkey `
            --ks-pass pass:android --key-pass pass:android --out $outputApk $apk.FullName
        if ($LASTEXITCODE -ne 0) { throw 'APK signing with the supplied debug keystore failed.' }
        & $apkSigner verify $outputApk
        if ($LASTEXITCODE -ne 0) { throw 'Signed APK verification failed.' }
    } else {
        Copy-Item -LiteralPath $apk.FullName -Destination $outputApk -Force
    }
    if ($VerifyPackage) {
        $abi = if ($Architecture -eq 'arm64') { 'arm64-v8a' } else { 'x86_64' }
        $readelf = Join-Path $ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
        $debugCheckArguments = @()
        if ($QmlDebug) {
            $debugCheckArguments = @('--qml-debug')
        }
        & $Python (Join-Path $PSScriptRoot 'tests/test_android_package.py') $outputApk `
            --abi $abi --readelf $readelf `
            --deployment-settings (Join-Path $appBuildDir 'android-application-deployment-settings.json') `
            @debugCheckArguments
        if ($LASTEXITCODE -ne 0) { throw 'Android package verification failed.' }
    }
    Write-Output "APK: $outputApk"
} finally {
    $env:JAVA_HOME = $previousJavaHome
}
