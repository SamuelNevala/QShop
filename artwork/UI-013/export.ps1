# Deterministic deployment exports; the approved PNG artwork remains unchanged.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$destination = Join-Path $projectRoot 'app/backgrounds'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$sources = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'inventory.json') -Raw | ConvertFrom-Json)
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
$parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]90)
try {
    $exports = foreach ($source in $sources) {
        $sourcePath = Join-Path $PSScriptRoot $source.file
        if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $source.sha256) {
            throw "Approved artwork hash mismatch: $sourcePath"
        }
        $name = [System.IO.Path]::GetFileNameWithoutExtension($source.file)
        if ($source.number -eq 8) { $name = '08-qshopper' }
        $outputPath = Join-Path $destination ($name + '.jpg')
        $image = [System.Drawing.Image]::FromFile($sourcePath)
        $bitmap = [System.Drawing.Bitmap]::new(1080, 1920, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $scale = [Math]::Max(1080.0 / $image.Width, 1920.0 / $image.Height)
            $cropWidth = 1080.0 / $scale
            $cropHeight = 1920.0 / $scale
            $crop = [System.Drawing.RectangleF]::new(($image.Width - $cropWidth) / 2, ($image.Height - $cropHeight) / 2, $cropWidth, $cropHeight)
            $graphics.DrawImage($image, [System.Drawing.RectangleF]::new(0, 0, 1080, 1920), $crop, [System.Drawing.GraphicsUnit]::Pixel)
            $bitmap.Save($outputPath, $jpeg, $parameters)
        } finally {
            $graphics.Dispose()
            $bitmap.Dispose()
            $image.Dispose()
        }
        [PSCustomObject]@{
            number = $source.number
            file = 'app/backgrounds/' + $name + '.jpg'
            width = 1080
            height = 1920
            quality = 90
            source_sha256 = $source.sha256
            sha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()
            bytes = (Get-Item -LiteralPath $outputPath).Length
        }
    }
    $exports | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'exports.json') -Encoding utf8
} finally {
    $parameters.Dispose()
}
