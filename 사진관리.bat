@echo off
chcp 65001 > nul
title 네일 포트폴리오 - 사진 관리
echo.
echo   사진 관리 창을 여는 중입니다... 잠시만 기다려 주세요.
echo   (브라우저가 자동으로 열립니다)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\server.ps1"
echo.
echo   서버가 종료되었습니다. 창을 닫으셔도 됩니다.
pause > nul
