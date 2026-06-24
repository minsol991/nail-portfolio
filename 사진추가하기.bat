@echo off
chcp 65001 > nul
title 사진 갤러리에 추가하기
echo.
echo   ========================================
echo      네일 포트폴리오 - 사진 등록 중...
echo   ========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\generate.ps1"
echo.
echo   창을 닫으려면 아무 키나 누르세요.
pause > nul
