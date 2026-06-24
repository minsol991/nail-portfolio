@echo off
chcp 65001 > nul
title Photo Manager
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\server.ps1"
pause
