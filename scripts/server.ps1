# ============================================================
#  사진 관리용 작은 로컬 서버.
#  "사진관리.bat" 더블클릭으로 실행됩니다. (직접 실행 X)
#  브라우저에서 사진을 끌어다 놓으면 images 폴더에 저장하고
#  갤러리(js/photos.js)를 자동으로 갱신합니다.
# ============================================================
$ErrorActionPreference = 'Stop'
chcp 65001 > $null
Add-Type -AssemblyName System.Drawing

$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$root         = Split-Path -Parent $scriptDir
$imagesDir    = Join-Path $root 'images'
$photosFile   = Join-Path $root 'js\photos.js'
$generatePath = Join-Path $scriptDir 'generate.ps1'
if (-not (Test-Path $imagesDir)) { New-Item -ItemType Directory -Path $imagesDir | Out-Null }

# ---------- 응답 도우미 ----------
function Send-Bytes($ctx, $status, $type, [byte[]]$bytes) {
    $r = $ctx.Response
    $r.StatusCode = $status
    $r.ContentType = $type
    $r.ContentLength64 = $bytes.Length
    $r.OutputStream.Write($bytes, 0, $bytes.Length)
    $r.OutputStream.Close()
}
function Send-Json($ctx, $obj) {
    $json = $obj | ConvertTo-Json -Compress -Depth 5
    Send-Bytes $ctx 200 "application/json; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes($json))
}
function Get-ContentType($path) {
    switch ([IO.Path]::GetExtension($path).ToLower()) {
        ".html" { "text/html; charset=utf-8" }
        ".css"  { "text/css; charset=utf-8" }
        ".js"   { "application/javascript; charset=utf-8" }
        ".json" { "application/json; charset=utf-8" }
        ".png"  { "image/png" }
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".webp" { "image/webp" }
        ".gif"  { "image/gif" }
        ".avif" { "image/avif" }
        ".svg"  { "image/svg+xml" }
        ".ico"  { "image/x-icon" }
        ".txt"  { "text/plain; charset=utf-8" }
        default { "application/octet-stream" }
    }
}

# ---------- 서버 시작 (빈 포트 자동 탐색) ----------
$listener = New-Object System.Net.HttpListener
$port = $null
foreach ($p in 8723..8743) {
    try {
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add("http://localhost:$p/")
        $listener.Start()
        $port = $p; break
    } catch { }
}
if (-not $port) { Write-Host "  서버를 시작할 수 없습니다." -ForegroundColor Red; pause; exit 1 }

$base = "http://localhost:$port"
Write-Host ""
Write-Host "  ======================================================" -ForegroundColor Cyan
Write-Host "     네일 포트폴리오 - 사진 관리 창이 열렸습니다." -ForegroundColor Cyan
Write-Host "     주소: $base/admin.html" -ForegroundColor Cyan
Write-Host "  ------------------------------------------------------" -ForegroundColor Cyan
Write-Host "     * 이 검은 창은 켜 둔 채로 사용하세요." -ForegroundColor DarkGray
Write-Host "     * 사진 작업이 끝나면 이 창을 그냥 닫으면 됩니다." -ForegroundColor DarkGray
Write-Host "  ======================================================" -ForegroundColor Cyan
Write-Host ""
Start-Process "$base/admin.html"

# ---------- 요청 처리 루프 ----------
while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
    } catch { break }
    try {
        $req  = $ctx.Request
        $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
        $method = $req.HttpMethod

        # ----- API: 현재 사진 목록 -----
        if ($path -eq "/api/photos" -and $method -eq "GET") {
            $arr = "[]"
            if (Test-Path $photosFile) {
                $txt = Get-Content -Raw -Encoding UTF8 $photosFile
                $s = $txt.IndexOf('['); $e = $txt.LastIndexOf(']')
                if ($s -ge 0 -and $e -gt $s) { $arr = $txt.Substring($s, $e - $s + 1) }
            }
            Send-Bytes $ctx 200 "application/json; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes($arr))
            continue
        }

        # ----- API: 사진 업로드 -----
        if ($path -eq "/api/upload" -and $method -eq "POST") {
            $fn = $req.Headers["X-Filename"]
            if ($fn) { $fn = [Uri]::UnescapeDataString($fn) }
            $fn = [IO.Path]::GetFileName($fn)
            if (-not $fn) { Send-Json $ctx @{ ok = $false; error = "파일명 없음" }; continue }

            $ms = New-Object System.IO.MemoryStream
            $req.InputStream.CopyTo($ms)
            $data = $ms.ToArray(); $ms.Dispose()

            # 같은 이름이 있으면 번호를 붙여 고유하게
            $name = [IO.Path]::GetFileNameWithoutExtension($fn)
            $ext  = [IO.Path]::GetExtension($fn)
            $dest = Join-Path $imagesDir $fn
            $i = 2
            while (Test-Path $dest) { $dest = Join-Path $imagesDir ("$name ($i)$ext"); $i++ }
            [IO.File]::WriteAllBytes($dest, $data)

            # 사진의 원래 날짜를 파일 날짜로 설정
            $lm = $req.Headers["X-LastModified"]
            if ($lm) {
                try {
                    $dt = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$lm).LocalDateTime
                    (Get-Item $dest).LastWriteTime = $dt
                } catch {}
            }
            Send-Json $ctx @{ ok = $true; name = [IO.Path]::GetFileName($dest) }
            continue
        }

        # ----- API: 사진 삭제 -----
        if ($path -eq "/api/delete" -and $method -eq "POST") {
            $ms = New-Object System.IO.MemoryStream
            $req.InputStream.CopyTo($ms)
            $body = [Text.Encoding]::UTF8.GetString($ms.ToArray()); $ms.Dispose()
            $ok = $false
            try {
                $obj = $body | ConvertFrom-Json
                $rel = $obj.src
                if ($rel -and $rel.StartsWith("images/") -and ($rel.IndexOf('..') -lt 0)) {
                    $target = Join-Path $root ($rel -replace '/', '\')
                    $full = [IO.Path]::GetFullPath($target)
                    if ($full.StartsWith([IO.Path]::GetFullPath($imagesDir)) -and (Test-Path $full)) {
                        Remove-Item $full -Force; $ok = $true
                    }
                }
            } catch {}
            Send-Json $ctx @{ ok = $ok }
            continue
        }

        # ----- API: 갤러리 다시 만들기 -----
        if ($path -eq "/api/regenerate" -and $method -eq "POST") {
            & $generatePath *> $null
            $cnt = (Get-ChildItem $imagesDir -Recurse -File |
                    Where-Object { @('.jpg','.jpeg','.png','.webp','.gif','.avif') -contains $_.Extension.ToLower() }).Count
            Send-Json $ctx @{ ok = $true; count = $cnt }
            continue
        }

        # ----- 정적 파일 -----
        $rel = $path.TrimStart('/')
        if ($rel -eq "") { $rel = "index.html" }
        $full = [IO.Path]::GetFullPath((Join-Path $root $rel))
        if (-not $full.StartsWith([IO.Path]::GetFullPath($root))) {
            Send-Bytes $ctx 403 "text/plain" ([Text.Encoding]::UTF8.GetBytes("forbidden")); continue
        }
        if (Test-Path $full -PathType Leaf) {
            Send-Bytes $ctx 200 (Get-ContentType $full) ([IO.File]::ReadAllBytes($full))
        } else {
            Send-Bytes $ctx 404 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("not found"))
        }
    } catch {
        try { Send-Bytes $ctx 500 "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("error: $($_.Exception.Message)")) } catch {}
    }
}
