# build_pos.ps1
# This script auto-increments the version in pubspec.yaml and runs a flutter build.

# Get the directory where this script is located
$scriptDir = $PSScriptRoot
# Determine project root (one level up from scripts folder)
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "Script Directory: $scriptDir" -ForegroundColor Gray
Write-Host "Project Root: $projectRoot" -ForegroundColor Gray

# Switch to project root
Push-Location $projectRoot

$pubspecPath = Join-Path $projectRoot "pubspec.yaml"

if (-not (Test-Path $pubspecPath)) {
    Write-Error "Could not find pubspec.yaml at $pubspecPath"
    Pop-Location
    exit 1
}

$content = Get-Content $pubspecPath -Raw

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
    
    Set-Content $pubspecPath $newContent -NoNewline
    Write-Host "Version incremented to: $newVersion" -ForegroundColor Green
} else {
    Write-Error "Could not find a valid version line in pubspec.yaml"
    Pop-Location
    exit 1
}

# Run Flutter Build
Write-Host "Starting Flutter Windows Build in $projectRoot..." -ForegroundColor Cyan
flutter clean
flutter build windows --release

Write-Host "Build Complete!" -ForegroundColor Green

# Return to original directory
Pop-Location
