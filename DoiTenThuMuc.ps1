\xef\xbb\xbf# DoiTenThuMuc.ps1 - Doi thu muc co dau sang ten khong dau (khop voi index.html moi).
$map = @{ "Hércules" = "hercules"; "Gimnàstic Tarragona" = "gimnastic-tarragona"; "Córdoba" = "cordoba"; "Xerez" = "xerez" }
Get-ChildItem "D:\KitAtlas\assets\kits" -Directory | ForEach-Object {
    foreach ($old in $map.Keys) {
        $src = Join-Path $_.FullName $old
        if (Test-Path -LiteralPath $src) {
            $dst = Join-Path $_.FullName $map[$old]
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Get-ChildItem -LiteralPath $src -File | Move-Item -Destination $dst -Force
            Remove-Item -LiteralPath $src
            Write-Host "Da doi: $($_.Name)\$old -> $($map[$old])"
        }
    }
}
Read-Host "Xong. Nhan Enter de dong"
