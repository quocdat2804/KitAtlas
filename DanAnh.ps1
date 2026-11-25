# DanAnh.ps1 - TU DONG luu anh khi ban "Copy image" tren trinh duyet.
# Sau khi chon CLB/mua giai, ban chi viec Copy image tung ao theo thu tu.
# Script tu thay doi clipboard va luu thanh JPG dung ten, dung thu muc.

$root      = "D:\KitAtlas\assets\kits"
$backupDir = "D:\KitAtlas\_backup"

function Get-ClipSeq { return [Win.Clip]::GetClipboardSequenceNumber() }

function Save-ClipboardJpg($dst, $season, $club, $type) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    if ($null -eq $img) { return $false }
    try {
        if (Test-Path $dst) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            Copy-Item -LiteralPath $dst -Destination (Join-Path $backupDir ("{0}_{1}_{2}_{3}.jpg" -f $season, $club, $type, $stamp)) -Force
        }
        $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::White)
        $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
        $g.Dispose()
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
        $ep = New-Object System.Drawing.Imaging.EncoderParameters 1
        $ep.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]90)
        $bmp.Save($dst, $codec, $ep)
        $bmp.Dispose()
    } finally { $img.Dispose() }
    return $true
}

# Cho den khi clipboard co ANH MOI. Tra ve $true neu co anh, $false neu nguoi dung bam S de bo qua.
function Wait-NewClipboardImage($lastSeq) {
    while ($true) {
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.KeyChar -eq 's' -or $k.KeyChar -eq 'S') { return $false }
        }
        Start-Sleep -Milliseconds 400
        $seq = Get-ClipSeq
        if ($seq -ne $lastSeq) {
            try {
                if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                    Start-Sleep -Milliseconds 300
                    return $true
                }
                $lastSeq = $seq   # clipboard doi nhung khong phai anh: bo qua
            } catch {
                # clipboard dang bi khoa, thu lai o vong sau
            }
        }
    }
}

try {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -Namespace Win -Name Clip -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();'

    while ($true) {
        Write-Host ""
        $club = Read-Host "CLB (ten thu muc, mac dinh real-madrid)"
        if ([string]::IsNullOrWhiteSpace($club)) { $club = "real-madrid" }
        $club = $club.Trim()
        $season = (Read-Host "Mua giai (vi du 2014-15)").Trim()
        if ($season -notmatch '^\d{4}-\d{2}$') {
            Write-Host "Mua giai phai co dang 2014-15. Thu lai." -ForegroundColor Red
            continue
        }
        $typesText = Read-Host "Cac loai ao (mac dinh home,away,third,goalkeeper)"
        if ([string]::IsNullOrWhiteSpace($typesText)) { $typesText = "home,away,third,goalkeeper" }
        $types = @($typesText.Split(",") | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })

        $destDir = Join-Path $root (Join-Path $season $club)
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null

        foreach ($type in $types) {
            Write-Host ""
            Write-Host ("[{0}] Dang cho... Hay 'Copy image' ao {0} tren trinh duyet. (Bam phim S de bo qua)" -f $type) -ForegroundColor Cyan
            $lastSeq = Get-ClipSeq
            $got = Wait-NewClipboardImage $lastSeq
            if (-not $got) { Write-Host "  Bo qua $type"; continue }
            $dst = Join-Path $destDir ($type + ".jpg")
            if (Save-ClipboardJpg $dst $season $club $type) {
                Write-Host ("  OK  {0}\{1}\{2}.jpg" -f $season, $club, $type) -ForegroundColor Green
            } else {
                Write-Host "  Khong doc duoc anh tu clipboard, thu Copy lai." -ForegroundColor Red
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
