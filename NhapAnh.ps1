# NhapAnh.ps1 - Doi ten va chuyen anh tu Downloads vao dung thu muc KitAtlas
# Cach dung: tai anh vao Downloads theo THU TU home, away, third, goalkeeper,
# roi chay script nay, nhap CLB va mua giai.

$root      = "D:\KitAtlas\assets\kits"
$downloads = Join-Path $env:USERPROFILE "Downloads"
$doneDir   = Join-Path $downloads "KitAtlas-daxong"
$backupDir = "D:\KitAtlas\_backup"
$exts      = @(".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif")

function Get-ImageKind($path) {
    $fs = [System.IO.File]::OpenRead($path)
    try {
        $b = New-Object byte[] 12
        [void]$fs.Read($b, 0, 12)
    } finally { $fs.Dispose() }
    if ($b[0] -eq 0xFF -and $b[1] -eq 0xD8) { return "jpeg" }
    if ($b[0] -eq 0x89 -and $b[1] -eq 0x50 -and $b[2] -eq 0x4E -and $b[3] -eq 0x47) { return "png" }
    if ($b[0] -eq 0x47 -and $b[1] -eq 0x49 -and $b[2] -eq 0x46) { return "gif" }
    if ($b[0] -eq 0x42 -and $b[1] -eq 0x4D) { return "bmp" }
    if ($b[0] -eq 0x52 -and $b[1] -eq 0x49 -and $b[2] -eq 0x46 -and $b[3] -eq 0x46 -and $b[8] -eq 0x57 -and $b[9] -eq 0x45 -and $b[10] -eq 0x42 -and $b[11] -eq 0x50) { return "webp" }
    return "unknown"
}

function Convert-ToJpg($src, $dst) {
    $kind = Get-ImageKind $src

    if ($kind -eq "jpeg") {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        return
    }

    if ($kind -eq "png" -or $kind -eq "gif" -or $kind -eq "bmp") {
        $img = [System.Drawing.Image]::FromFile($src)
        try {
            $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.Clear([System.Drawing.Color]::White)
            $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
            $g.Dispose()
            $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            $bmp.Dispose()
        } finally { $img.Dispose() }
        return
    }

    # webp va dinh dang khac: dung bo giai ma cua Windows (WPF)
    $stream = $null
    try {
        $stream = [System.IO.File]::OpenRead($src)
        $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
            $stream,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
        $frame = $decoder.Frames[0]
        $w = $frame.PixelWidth
        $h = $frame.PixelHeight
        $rect = New-Object System.Windows.Rect 0, 0, $w, $h

        # ve len nen trang de anh trong suot khong bi den
        $visual = New-Object System.Windows.Media.DrawingVisual
        $dc = $visual.RenderOpen()
        $dc.DrawRectangle([System.Windows.Media.Brushes]::White, $null, $rect)
        $dc.DrawImage($frame, $rect)
        $dc.Close()
        $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap $w, $h, 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
        $rtb.Render($visual)

        $encoder = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
        $encoder.QualityLevel = 85
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
        $out = [System.IO.File]::Create($dst)
        try { $encoder.Save($out) } finally { $out.Dispose() }
    }
    catch {
        throw ("Khong doc duoc anh (dinh dang that: {0}). Neu la webp: cai 'WebP Image Extensions' tu Microsoft Store, hoac mo anh bang Paint roi Save as JPEG. Chi tiet: {1}" -f $kind, $_.Exception.Message)
    }
    finally { if ($stream) { $stream.Dispose() } }
}

try {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    while ($true) {
        Write-Host ""
        $club = Read-Host "CLB (ten thu muc, mac dinh real-madrid)"
        if ([string]::IsNullOrWhiteSpace($club)) { $club = "real-madrid" }
        $season = Read-Host "Mua giai (vi du 2014-15)"
        if ($season -notmatch '^\d{4}-\d{2}$') {
            Write-Host "Mua giai phai co dang 2014-15. Thu lai." -ForegroundColor Red
            continue
        }
        $typesText = Read-Host "Cac loai ao theo thu tu tai (mac dinh home,away,third,goalkeeper)"
        if ([string]::IsNullOrWhiteSpace($typesText)) { $typesText = "home,away,third,goalkeeper" }
        $types = @($typesText.Split(",") | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })

        # lay N anh moi nhat trong Downloads, xep tu cu den moi
        $files = @(Get-ChildItem -LiteralPath $downloads -File |
            Where-Object { $exts -contains $_.Extension.ToLower() } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First $types.Count |
            Sort-Object LastWriteTime)

        if ($files.Count -lt $types.Count) {
            Write-Host "Chi tim thay $($files.Count) anh trong $downloads, can $($types.Count). Tai them anh roi thu lai." -ForegroundColor Red
            continue
        }

        $destDir = Join-Path $root (Join-Path $season $club)
        Write-Host ""
        Write-Host "Se thuc hien:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $types.Count; $i++) {
            $dst = Join-Path $destDir ($types[$i] + ".jpg")
            $note = ""
            if (Test-Path $dst) { $note = "  (GHI DE file cu)" }
            Write-Host ("  {0} [tai luc {1}]  ->  {2}\{3}\{4}.jpg{5}" -f $files[$i].Name, $files[$i].LastWriteTime.ToString("dd/MM HH:mm:ss"), $season, $club, $types[$i], $note)
        }
        $ok = Read-Host "Dung khong? (Y/N)"
        if ($ok -notmatch '^[Yy]') { Write-Host "Bo qua."; continue }

        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        New-Item -ItemType Directory -Path $doneDir -Force | Out-Null
        for ($i = 0; $i -lt $types.Count; $i++) {
            $dst = Join-Path $destDir ($types[$i] + ".jpg")
            try {
                if (Test-Path $dst) {
                    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    Copy-Item -LiteralPath $dst -Destination (Join-Path $backupDir ("{0}_{1}_{2}_{3}.jpg" -f $season, $club, $types[$i], $stamp)) -Force
                }
                Convert-ToJpg $files[$i].FullName $dst
                Move-Item -LiteralPath $files[$i].FullName -Destination $doneDir -Force
                Write-Host ("  OK  {0}.jpg" -f $types[$i]) -ForegroundColor Green
            } catch {
                Write-Host ("  LOI {0}: {1}" -f $files[$i].Name, $_.Exception.Message) -ForegroundColor Red
            }
        }
        $again = Read-Host "Lam mua tiep? (Y/N)"
        if ($again -notmatch '^[Yy]') { break }
    }
}
catch {
    Write-Host ""
    Write-Host "CO LOI: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "Nhan Enter de dong cua so nay"
}
