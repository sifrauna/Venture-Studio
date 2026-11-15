@echo off
title Venture Studio
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -StartOnly %*
echo.
pause
