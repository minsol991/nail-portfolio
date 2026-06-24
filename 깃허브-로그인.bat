@echo off
chcp 65001 > nul
title 깃허브 로그인 (한 번만 하면 됩니다)
set "GH=%ProgramFiles%\GitHub CLI\gh.exe"
echo.
echo   =====================================================
echo      깃허브 로그인 (토큰 방식)
echo   =====================================================
echo.
echo   준비물: 깃허브 토큰 (아래 순서대로 만드세요)
echo.
echo     1) 브라우저에 열린 "New personal access token" 페이지에서
echo        맨 아래로 스크롤
echo     2) 초록색 [Generate token] 버튼 클릭
echo     3) 새로 나온 토큰(ghp_ 로 시작하는 긴 글자) 전체를 복사
echo        (토큰 옆 복사 아이콘을 누르면 편해요)
echo     4) 이 검은 창에 붙여넣기:
echo        - 마우스 오른쪽 클릭 한 번 하면 붙여넣어집니다
echo     5) Enter 누르기
echo.
echo   -----------------------------------------------------
echo.
set /p TOKEN=여기에 토큰 붙여넣고 Enter:
echo %TOKEN%| "%GH%" auth login --hostname github.com --git-protocol https --with-token
"%GH%" auth setup-git
echo.
echo   -----------------------------------------------------
"%GH%" auth status
echo.
echo   위에 "Logged in to github.com as ..." 가 보이면 성공입니다!
echo   클로드에게 "로그인 완료" 라고 알려주세요.
echo.
pause
