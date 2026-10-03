# Windows equivalent of setup.sh
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Test-Path "android")) {
  flutter create . --platforms=android --org in.ac.lbrce --project-name rescuegrid
}
Copy-Item -Force "android_overrides/AndroidManifest.xml" "android/app/src/main/AndroidManifest.xml"
flutter pub get
Write-Host "Setup complete. Next: flutter analyze; flutter test; flutter build apk --release"
