@echo off
setlocal
cd /d "%~dp0"
echo ============================================
echo  Motorcycle Race Manager - Chrome Launcher
echo ============================================
echo.

set "FLUTTER_CMD=flutter"
if exist "C:\f\bin\flutter.bat" set "FLUTTER_CMD=C:\f\bin\flutter.bat"

if "%FLUTTER_CMD%"=="C:\f\bin\flutter.bat" (
  if not exist "C:\f\bin\flutter.bat" goto :no_flutter
) else (
  where flutter >nul 2>nul
  if errorlevel 1 goto :no_flutter
)

goto :flutter_ok

:no_flutter
  echo [ERROR] Flutter is not installed and local SDK not found at C:\f.
  echo Install Flutter or place SDK at C:\f.
  echo.
  pause
  exit /b 1

:flutter_ok

echo [1/3] flutter create .
call %FLUTTER_CMD% create .
if errorlevel 1 goto :failed

echo [2/3] flutter pub get
call %FLUTTER_CMD% pub get
if errorlevel 1 goto :failed

echo [3/3] flutter run -d chrome
call %FLUTTER_CMD% run -d chrome
if errorlevel 1 goto :failed

goto :eof

:failed
echo.
echo [FAILED] Launch stopped due to the error above.
pause
exit /b 1
