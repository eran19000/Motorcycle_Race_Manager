@echo off
setlocal
set "TARGET=%~dp0preview_high_contrast_dashboard.html"

if not exist "%TARGET%" (
  echo Missing file: %TARGET%
  pause
  exit /b 1
)

start "" "%TARGET%"
