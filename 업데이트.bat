@echo off
chcp 65001 > nul
title 사이트 업데이트 (인터넷에 반영하기)
cd /d "%~dp0"
echo.
echo   =====================================================
echo      인터넷 사이트에 최신 사진 반영하기
echo   =====================================================
echo.
echo   갤러리를 정리하는 중...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\generate.ps1" > nul
echo   인터넷에 올리는 중...
git add -A
git commit -m "사진 업데이트"
git push
echo.
echo   -----------------------------------------------------
echo   완료! 1~2분 뒤 아래 주소에 반영됩니다:
echo.
echo      https://minsol991.github.io/nail-portfolio/
echo   -----------------------------------------------------
echo.
echo   ※ "로그인이 필요하다"거나 오류가 나오면,
echo     먼저 "깃허브-로그인.bat" 을 한 번 실행해 주세요.
echo.
pause
