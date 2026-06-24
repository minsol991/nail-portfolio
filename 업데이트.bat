@echo off
chcp 65001 > nul
title Update Site
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\publish.ps1"
pause
