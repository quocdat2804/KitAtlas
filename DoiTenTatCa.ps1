\xef\xbb\xbf# DoiTenTatCa.ps1 - Doi TEN TAT CA thu muc CLB trong moi mua sang dang khong dau, viet thuong, noi bang dau gach.
# Vi du: "Almeria" -> almeria, "Celta Vigo" -> celta-vigo, "Deportivo La Coruna" -> deportivo-la-coruna.
# An toan: chi doi ten, neu thu muc dich da co thi GOP file (khong ghi de file da co).

$root = "D:\KitAtlas\assets\kits"

function Get-Slug($name) {
    $d = $name.Trim().Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $d.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $s = $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC).ToLowerInvariant()
    return ($s -replace '\s+', '-')
}

try {
    $plan = @()
    Get-ChildItem -LiteralPath $root -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}$' } | ForEach-Object {
        $season = $_
        Get-ChildItem -LiteralPath $season.FullName -Directory | ForEach-Object {
            $slug = Get-Slug $_.Name
            if ($_.Name -cne $slug) {
                $plan += [pscustomobject]@{ Season = $season.Name; Old = $_.Name; New = $slug; Path = $_.FullName; Parent = $season.FullName }
            }
        }
    }

    if ($plan.Count -eq 0) {
        Write-Host "Khong co thu muc nao can doi ten." -ForegroundColor Green
        return
    }

    Write-Host ("Se doi ten {0} thu muc. Vi du:" -f $plan.Count) -ForegroundColor Cyan
    $plan | Select-Object -First 15 | ForEach-Object { Write-Host ("  {0}\{1}  ->  {2}" -f $_.Season, $_.Old, $_.New) }
    $plan | Group-Object Old | Sort-Object Name | ForEach-Object { Write-Host ("  [{0} mua] {1}  ->  {2}" -f $_.Count, $_.Name, $_.Group[0].New) }
    $ok = Read-Host "Dong y doi ten? (Y/N)"
    if ($ok -notmatch '^[Yy]') { Write-Host "Da huy."; return }

    $done = 0; $merged = 0; $failed = 0
    foreach ($p in $plan) {
        try {
            $target = Join-Path $p.Parent $p.New
            $sameFolder = [string]::Equals($p.Old, $p.New, [System.StringComparison]::OrdinalIgnoreCase)
            if ($sameFolder -or -not (Test-Path -LiteralPath $target)) {
                # doi ten 2 buoc de Windows chap nhan doi chu hoa/thuong
                $tmp = "_tmp_" + [guid]::NewGuid().ToString("N")
                Rename-Item -LiteralPath $p.Path -NewName $tmp -ErrorAction Stop
                Rename-Item -LiteralPath (Join-Path $p.Parent $tmp) -NewName $p.New -ErrorAction Stop
                $done++
            } else {
                # thu muc dich da ton tai: gop file, khong ghi de
                Get-ChildItem -LiteralPath $p.Path -File | ForEach-Object {
                    $dst = Join-Path $target $_.Name
                    if (Test-Path -LiteralPath $dst) {
                        Write-Host ("  BO QUA (da co): {0}\{1}\{2}" -f $p.Season, $p.New, $_.Name) -ForegroundColor Yellow
                    } else {
                        Move-Item -LiteralPath $_.FullName -Destination $dst
                    }
                }
                if (-not (Get-ChildItem -LiteralPath $p.Path -Force)) { Remove-Item -LiteralPath $p.Path }
                $merged++
            }
        } catch {
            $failed++
            Write-Host ("  LOI {0}\{1}: {2}" -f $p.Season, $p.Old, $_.Exception.Message) -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host ("XONG. Doi ten: {0} | Gop: {1} | Loi: {2}" -f $done, $merged, $failed) -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "CO LOI: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "Nhan Enter de dong cua so nay"
}
