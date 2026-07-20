@echo off
:: build.bat — Build wrapper that calls build.ps1
:: NOTE: batch file must be saved as ANSI (not UTF-8 BOM) to work correctly
::       in cmd.exe. If you see "'tlocal' is not recognized", re-save as ANSI.
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    exit /b 1
)