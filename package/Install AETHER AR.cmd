@echo off
title AETHER AR - Setup
rem AETHER AR -- double-click to install: opens the Setup window (the console closes at once). Needs your own
rem Budokai Tenkaichi 3 (USA) ISO and an internet connection. (setup\install-aether-ar.ps1 is the same install without
rem the window, for a terminal.)
rem Started from inside the ZIP (Explorer copies only this file to a temp folder), the setup folder is not next to it.
if not exist "%~dp0setup\setup-gui.ps1" (
    echo.
    echo   Please unpack the ZIP first: right-click AETHER-AR-*.zip ^> Extract All...
    echo   Then double-click "Install AETHER AR.cmd" in the unpacked folder.
    echo.
    pause
    exit /b 1
)
rem (/min: on Windows 11 a normal start hands the console to a Windows Terminal window that stays in the taskbar, and
rem closing it closed Setup; minimized, powershell's own -WindowStyle Hidden then hides it for good)
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0setup\setup-gui.ps1"
