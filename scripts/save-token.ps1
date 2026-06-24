# ============================================================
#  깃허브 토큰을 윈도우 자격 증명에 저장합니다.
#  복사해 둔 토큰을 클립보드에서 자동으로 가져옵니다.
#  "깃허브-로그인.bat" 이 이 파일을 실행합니다.
# ============================================================
$ErrorActionPreference = 'Stop'
chcp 65001 > $null

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "     깃허브 토큰 저장" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

# 1) 클립보드에서 토큰 자동 인식
$t = ""
try { $t = (Get-Clipboard -Raw) } catch {}
if ($t) { $t = $t.Trim() }

if ($t -match '^gh[a-z]_[A-Za-z0-9_]{20,}$') {
    Write-Host "  복사해 둔 토큰을 찾았어요. 저장합니다..." -ForegroundColor Green
} else {
    Write-Host "  복사된 토큰을 못 찾았어요." -ForegroundColor Yellow
    Write-Host "  토큰(ghp_ 로 시작)을 복사한 뒤 이 창을 닫고 다시 실행하거나,"
    Write-Host "  아래에 직접 붙여넣어도 됩니다. (마우스 오른쪽 클릭 = 붙여넣기)"
    Write-Host ""
    $t = (Read-Host "  토큰 붙여넣고 Enter").Trim()
}
if (-not $t) { Write-Host "  토큰이 없습니다. 다시 시도해 주세요." -ForegroundColor Red; return }

# 2) 기존(무효) 자격 증명 삭제
$e = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($e, "protocol=https`nhost=github.com`n`n")
cmd /c "git credential reject < `"$e`"" 2>$null
Remove-Item $e -Force

# 3) 새 자격 증명 저장
$f = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($f, "protocol=https`nhost=github.com`nusername=minsol991`npassword=$t`n`n")
cmd /c "git credential approve < `"$f`""
Remove-Item $f -Force

Write-Host ""
Write-Host "  저장 완료! 클로드에게 '완료' 라고 알려주세요." -ForegroundColor Green
Write-Host ""
