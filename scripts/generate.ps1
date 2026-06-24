# ============================================================
#  images 폴더를 읽어서 js/photos.js 를 자동으로 만들어 줍니다.
#  각 사진의 "작업 날짜"는 아래 순서로 정합니다.
#    1) 파일 이름이 날짜로 시작하면 그 날짜  (예: 2026-06-20 글리터.jpg)
#    2) 사진에 기록된 촬영 날짜 (EXIF)
#    3) 파일을 마지막으로 저장한 날짜
#  최신 작업이 맨 앞에 오도록 정렬됩니다.
#  (직접 실행하지 말고 "사진추가하기.bat" 를 더블클릭하세요)
# ============================================================
$ErrorActionPreference = 'Stop'
chcp 65001 > $null   # 한글 깨짐 방지
Add-Type -AssemblyName System.Drawing

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$imagesDir   = Join-Path $projectRoot 'images'
$outFile     = Join-Path $projectRoot 'js\photos.js'

$exts = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif')

function Get-PhotoDate {
    param($file)
    # 1) 파일 이름이 날짜로 시작하면 그 날짜 사용
    if ($file.BaseName -match '^(\d{4})[-_. ]?(\d{2})[-_. ]?(\d{2})') {
        try {
            return Get-Date -Year $matches[1] -Month $matches[2] -Day $matches[3] -Hour 0 -Minute 0 -Second 0
        } catch {}
    }
    # 2) 사진에 기록된 촬영 날짜 (EXIF DateTimeOriginal)
    if ($file.Extension -match '(?i)\.(jpg|jpeg)$') {
        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            try {
                $prop = $img.GetPropertyItem(36867)
                $txt  = [System.Text.Encoding]::ASCII.GetString($prop.Value).Trim([char]0).Trim()
                return [datetime]::ParseExact($txt.Substring(0, 19), 'yyyy:MM:dd HH:mm:ss', $null)
            } finally { $img.Dispose() }
        } catch {}
    }
    # 3) 파일 수정 날짜
    return $file.LastWriteTime
}

$rows = New-Object System.Collections.Generic.List[object]

if (Test-Path $imagesDir) {
    Get-ChildItem -Path $imagesDir -Recurse -File |
        Where-Object { $exts -contains $_.Extension.ToLower() } |
        ForEach-Object {
            $date = Get-PhotoDate $_
            # 작품 제목 = 파일 이름 (맨 앞 날짜는 떼어냄)
            $name = $_.BaseName
            if ($name -match '^(\d{4})[-_. ]?(\d{2})[-_. ]?(\d{2})[ _-]*(.*)$') { $name = $matches[4] }
            $name = $name.Trim()
            $rel  = $_.FullName.Substring($projectRoot.Length).TrimStart('\', '/').Replace('\', '/')
            $rows.Add([pscustomobject]@{
                src  = $rel
                name = $name
                date = $date
                disp = $date.ToString('yyyy.MM.dd')
            })
        }
}

# 최신 날짜가 맨 위로
$sorted = $rows | Sort-Object date -Descending

$lines = New-Object System.Collections.Generic.List[string]
foreach ($r in $sorted) {
    $s = $r.src.Replace('"', '\"')
    $n = $r.name.Replace('\', '\\').Replace('"', '\"')
    $d = $r.disp
    $lines.Add('  { "src": "' + $s + '", "name": "' + $n + '", "date": "' + $d + '" }')
}

$count  = $sorted.Count
$header = @"
/* ============================================================
   이 파일은 자동으로 만들어집니다. 직접 고치지 마세요!
   ($count 장의 사진이 등록되었습니다)
   ============================================================ */
const PHOTOS = [
"@
$body    = ($lines -join ",`r`n")
$content = $header + "`r`n" + $body + "`r`n];`r`n"

# UTF-8 로 저장
$enc = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outFile, $content, $enc)

Write-Host ""
Write-Host "  완료!  사진 $count 장이 갤러리에 등록되었습니다." -ForegroundColor Green
Write-Host "  index.html 을 새로고침하면 보입니다." -ForegroundColor Green
Write-Host ""
