@echo off
cd /d "%~dp0"
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0DanAnh.ps1"
echo.
pause
