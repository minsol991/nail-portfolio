# ============================================================
#  갤러리를 다시 만들고 인터넷 사이트에 반영(push)합니다.
#  "업데이트.bat" 이 이 파일을 실행합니다.
# ============================================================
chcp 65001 > $null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$env:GIT_TERMINAL_PROMPT = "0"

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "     인터넷 사이트에 반영하기" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) 갤러리 정리 중..."
& "$scriptDir\generate.ps1" | Out-Null

Write-Host "  2) 인터넷에 올리는 중..."
git -C $root add -A 2>&1 | Out-Null
git -C $root commit -m "Update photos" 2>&1 | Out-Null
$push = git -C $root push 2>&1
$code = $LASTEXITCODE

Write-Host ""
if ($code -eq 0) {
    Write-Host "  ============================================" -ForegroundColor Green
    Write-Host "     완료! 1~2분 뒤 아래 주소에 반영됩니다:" -ForegroundColor Green
    Write-Host "     https://minsol991.github.io/nail-portfolio/" -ForegroundColor Green
    Write-Host "  ============================================" -ForegroundColor Green
} else {
    Write-Host "  ----- 문제가 생겼어요 -----" -ForegroundColor Yellow
    Write-Host $push
    Write-Host ""
    Write-Host "  '로그인/인증' 관련 오류라면 '깃허브-로그인.bat' 을 먼저 실행한 뒤" -ForegroundColor Yellow
    Write-Host "  다시 시도해 주세요." -ForegroundColor Yellow
}
Write-Host ""
