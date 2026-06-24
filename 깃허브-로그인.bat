@echo off
chcp 65001 > nul
title 깃허브 토큰 저장 (업데이트가 안 될 때만 사용)
echo.
echo   =====================================================
echo      깃허브 토큰 저장
echo   =====================================================
echo.
echo   "업데이트.bat" 에서 로그인 오류가 날 때 이걸 실행하세요.
echo.
echo   토큰 만드는 법:
echo     1) 브라우저에서 아래 주소 열기
echo        https://github.com/settings/tokens/new?scopes=repo,workflow
echo     2) 맨 아래 [Generate token] 클릭
echo     3) ghp_ 로 시작하는 토큰을 복사
echo     4) 이 창에 붙여넣기(마우스 오른쪽 클릭) 후 Enter
echo.
echo   -----------------------------------------------------
echo.
set /p TOKEN=토큰 붙여넣고 Enter:
(
echo protocol=https
echo host=github.com
echo username=minsol991
echo password=%TOKEN%
echo.
)| git credential approve
echo.
echo   저장 완료! 이제 "업데이트.bat" 이 정상 작동합니다.
echo.
pause
