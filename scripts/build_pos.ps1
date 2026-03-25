# build_pos.ps1
# This script auto-increments the version in pubspec.yaml and runs a flutter build.

$pubspecFile = "..\pubspec.yaml"
$content = Get-Content $pubspecFile -Raw

# Match version: x.y.z+n
if ($content -match 'version: (\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $build = [int]$Matches[4]

    # Increment patch version for next build
    $patch++
    $build++

    $newVersion = "$major.$minor.$patch+$build"
    $newContent = $content -replace 'version: \d+\.\d+\.\d+\+\d+', "version: $newVersion"
    
    Set-Content $pubspecFile $newContent
    Write-Host "Version incremented to: $newVersion" -ForegroundColor Green
} else {
    Write-Error "Could not find a valid version line in pubspec.yaml"
    exit 1
}

# Run Flutter Build
Write-Host "Starting Flutter Windows Build..." -ForegroundColor Cyan
flutter clean
flutter build windows --release

Write-Host "Build Complete!" -ForegroundColor Green
