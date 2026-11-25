\xef\xbb\xbf# KiemTra.ps1 - So sanh index.html voi anh that tren o D:, bao cao anh con thieu / anh thua.
$site = "D:\KitAtlas"
try {
    $html = Get-Content -LiteralPath (Join-Path $site "index.html") -Raw -Encoding UTF8
    $refs = [regex]::Matches($html, 'image:\s*"(assets/kits/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $missing = @($refs | Where-Object { -not (Test-Path -LiteralPath (Join-Path $site ($_ -replace '/', '\'))) })
    Write-Host ("index.html tham chieu {0} anh, CON THIEU {1}." -f $refs.Count, $missing.Count) -ForegroundColor Cyan
    $missing | Group-Object { ($_ -split '/')[3] } | Sort-Object Count -Descending | ForEach-Object { Write-Host ("  {0}: thieu {1}" -f $_.Name, $_.Count) }
    $missing | Set-Content -LiteralPath (Join-Path $site "_anh-con-thieu.txt") -Encoding UTF8
    Write-Host "Danh sach day du: D:\KitAtlas\_anh-con-thieu.txt" -ForegroundColor Green

    $onDisk = Get-ChildItem (Join-Path $site "assets\kits") -Recurse -File -Filter *.jpg | ForEach-Object { ($_.FullName.Substring($site.Length + 1)) -replace '\\', '/' }
    $extra = @($onDisk | Where-Object { $refs -notcontains $_ })
    Write-Host ("Anh co tren o dia nhung CHUA co trong index.html: {0}" -f $extra.Count) -ForegroundColor Yellow
    $extra | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" }
}
catch { Write-Host "CO LOI: $($_.Exception.Message)" -ForegroundColor Red }
finally { Read-Host "Nhan Enter de dong cua so nay" }
