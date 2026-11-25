# TaoThuMuc.ps1 - Tao san toan bo thu muc anh cho KitAtlas
# Sua danh sach CLB o dong $clubs neu can.

$root      = "D:\KitAtlas\assets\kits"
$clubs     = @("real-madrid", "barcelona", "real-betis", "athletic-bilbao", "valencia", "sevilla", "villarreal", "atletico-madrid", "espanyol", "real-sociedad", "osasuna", "getafe", "celta-vigo", "mallorca", "deportivo-la-coruna", "malaga", "levante", "rayo-vallecano", "real-valladolid", "deportivo-alaves", "racing-santander", "real-zaragoza", "granada", "almeria", "eibar", "las-palmas", "elche", "girona", "sporting-gijon", "cadiz", "leganes", "recreativo-huelva", "numancia", "albacete", "tenerife", "real-murcia", "real-oviedo", "huesca", "cordoba", "gimnastic-tarragona", "hercules", "xerez")
$firstYear = 2000
$lastYear  = 2026

try {
    $ErrorActionPreference = "Stop"
    $created = 0
    for ($y = $firstYear; $y -le $lastYear; $y++) {
        $season = "{0}-{1:00}" -f $y, (($y + 1) % 100)
        foreach ($club in $clubs) {
            $path = Join-Path $root (Join-Path $season $club)
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                $created++
                Write-Host "Da tao: $path"
            }
        }
    }
    Write-Host ""
    Write-Host "XONG. Da tao $created thu muc moi trong $root" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "CO LOI: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "Nhan Enter de dong cua so nay"
}
