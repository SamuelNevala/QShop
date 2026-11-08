param(
    [string]$QtRoot = 'C:\Qt',
    [string]$QtVersion = '6.12.0',
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$NdkVersion = '27.2.12479018',
    [string]$JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot',
    [ValidateSet('arm64', 'x86_64')][string]$Architecture = 'arm64',
    [ValidateSet('Debug', 'Release', 'MinSizeRel')][string]$Configuration = 'Debug',
    [switch]$AppBundle,
    [string]$Bundletool = '',
    [string]$DebugKeystore = '',
    [switch]$VerifyPackage,
    [switch]$QmlDebug,
    [string]$Python = 'python',
    [ValidateRange(1, 64)][int]$Jobs = 4
)

$ErrorActionPreference = 'Stop'
if ($Configuration -ne 'Debug' -and ($DebugKeystore -or $QmlDebug)) {
    throw 'Release artifacts are unsigned; DebugKeystore and QmlDebug apply only to Debug.'
}
if ($AppBundle -and $Configuration -eq 'Debug') {
    throw 'AppBundle requires Release or MinSizeRel.'
}
if ($AppBundle -and $VerifyPackage -and
    (-not $Bundletool -or !(Test-Path -LiteralPath $Bundletool -PathType Leaf))) {
    throw 'AppBundle verification requires -Bundletool pointing to the official bundletool JAR.'
}
$buildFolder = if ($Configuration -ne 'Debug') {
    "out/android-$Architecture-$($Configuration.ToLowerInvariant())"
} elseif ($Architecture -eq 'arm64') { 'build-android-arm64' } else { 'out/android-emulator-build' }
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
$previousGradleOptions = $env:GRADLE_OPTS
try {
    $env:JAVA_HOME = $JavaHome
    # Do not leave a persistent Gradle daemon holding the command open.
    $env:GRADLE_OPTS = "$previousGradleOptions -Dorg.gradle.daemon=false".Trim()
    $qmlDebugSetting = if ($QmlDebug) { 'ON' } else { 'OFF' }
    $sizeOptimization = if ($Configuration -eq 'MinSizeRel') { 'ON' } else { 'OFF' }
    & $qtCmake -S $PSScriptRoot -B $buildDir -G Ninja `
        "-DCMAKE_MAKE_PROGRAM=$ninja" "-DCMAKE_BUILD_TYPE=$Configuration" -DBUILD_TESTING=OFF `
        "-DQT_HOST_PATH=$hostQt" "-DANDROID_SDK_ROOT=$SdkRoot" "-DANDROID_NDK_ROOT=$ndk" `
        "-DQT_ENABLE_QML_DEBUG=$qmlDebugSetting" "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=$sizeOptimization" `
        -DQT_ANDROID_SIGN_APK=OFF -DQT_ANDROID_SIGN_AAB=OFF
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
    $packageTarget = if ($AppBundle) { 'aab' } else { 'apk' }
    & $cmake --build $buildDir --target $packageTarget --parallel $Jobs
    if ($LASTEXITCODE -ne 0) { throw 'Android package build failed.' }

    $artifactPattern = if ($AppBundle) { '*-release.aab' } elseif ($Configuration -eq 'Debug') {
        '*-debug.apk'
    } else { '*-release-unsigned.apk' }
    $artifacts = @(Get-ChildItem "$appBuildDir/android-build/build/outputs" -Recurse -Filter $artifactPattern)
    if ($artifacts.Count -ne 1) { throw "Expected exactly one $artifactPattern artifact; found $($artifacts.Count)." }
    $artifact = $artifacts[0]
    $outputDir = Join-Path $PSScriptRoot 'dist'
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    $artifactSuffix = if ($Configuration -eq 'Debug') { 'debug' } else { 'release-unsigned' }
    $extension = if ($AppBundle) { 'aab' } else { 'apk' }
    $outputApk = Join-Path $outputDir "QShopper-$Architecture-$artifactSuffix.$extension"
    if ($DebugKeystore) {
        $deployment = Get-Content -Raw (Join-Path $appBuildDir 'android-application-deployment-settings.json') |
            ConvertFrom-Json
        $apkSigner = Join-Path $SdkRoot "build-tools/$($deployment.sdkBuildToolsRevision)/apksigner.bat"
        if (!(Test-Path -LiteralPath $apkSigner)) { throw "APK signer not found: $apkSigner" }
        & $apkSigner sign --ks $DebugKeystore --ks-key-alias androiddebugkey `
            --ks-pass pass:android --key-pass pass:android --out $outputApk $artifact.FullName
        if ($LASTEXITCODE -ne 0) { throw 'APK signing with the supplied debug keystore failed.' }
        & $apkSigner verify $outputApk
        if ($LASTEXITCODE -ne 0) { throw 'Signed APK verification failed.' }
    } else {
        Copy-Item -LiteralPath $artifact.FullName -Destination $outputApk -Force
    }
    if ($VerifyPackage) {
        $abi = if ($Architecture -eq 'arm64') { 'arm64-v8a' } else { 'x86_64' }
        $readelf = Join-Path $ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
        $debugCheckArguments = @()
        if ($QmlDebug) {
            $debugCheckArguments = @('--qml-debug')
        }
        if ($Configuration -eq 'Debug') {
            & $Python (Join-Path $PSScriptRoot 'tests/test_android_package.py') $outputApk `
                --abi $abi --readelf $readelf `
                --deployment-settings (Join-Path $appBuildDir 'android-application-deployment-settings.json') `
                @debugCheckArguments
        } else {
            $releaseCheckArguments = @()
            if ($AppBundle) {
                $releaseCheckArguments = @('--bundletool', $Bundletool)
            }
            & $Python (Join-Path $PSScriptRoot 'tests/test_android_release.py') $outputApk `
                --abi $abi --readelf $readelf --java (Join-Path $JavaHome 'bin/java.exe') `
                @releaseCheckArguments `
                --deployment-settings (Join-Path $appBuildDir 'android-application-deployment-settings.json') `
                --report (Join-Path $outputDir "QShopper-$Architecture-release-$extension.json")
        }
        if ($LASTEXITCODE -ne 0) { throw 'Android package verification failed.' }
    }
    Write-Output "Package: $outputApk"
} finally {
    $env:JAVA_HOME = $previousJavaHome
    $env:GRADLE_OPTS = $previousGradleOptions
}
