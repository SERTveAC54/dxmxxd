# Fixture Manifest Oluşturucu
# Tüm QXF ve JSON dosyalarının listesini içeren bir manifest oluşturur

Write-Host "Fixture manifest olusturuluyor..." -ForegroundColor Cyan

$fixtures = @()

# Tüm QXF ve JSON dosyalarını bul
Get-ChildItem "assets\fixtures\" -Recurse -Include "*.qxf","*.json" | ForEach-Object {
    $relativePath = $_.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
    $fixtures += $relativePath
}

# JSON formatında kaydet
$manifest = @{
    "fixtures" = $fixtures
    "count" = $fixtures.Count
    "generated" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$json = $manifest | ConvertTo-Json -Depth 10
$json | Out-File "assets\fixtures\fixture_manifest.json" -Encoding UTF8

Write-Host "Manifest olusturuldu!" -ForegroundColor Green
Write-Host "Dosya sayisi: $($fixtures.Count)" -ForegroundColor White
Write-Host "Konum: assets\fixtures\fixture_manifest.json" -ForegroundColor White
