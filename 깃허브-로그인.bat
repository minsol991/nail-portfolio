@echo off
chcp 65001 > nul
title GitHub Login
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\save-token.ps1"
pause
