# Tüm fixture'ları manufacturer bilgisiyle birleştir
$allFixtures = @()

Get-ChildItem -Path "assets/fixtures" -Recurse -Filter "*.json" -Exclude "library*.json" | ForEach-Object {
    try {
        $manufacturer = $_.Directory.Name
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        
        if ($content -is [Array]) {
            foreach ($fixture in $content) {
                if (-not $fixture.manufacturer) {
                    $fixture | Add-Member -NotePropertyName "manufacturer" -NotePropertyValue $manufacturer -Force
                }
                $allFixtures += $fixture
            }
        } else {
            if (-not $content.manufacturer) {
                $content | Add-Member -NotePropertyName "manufacturer" -NotePropertyValue $manufacturer -Force
            }
            $allFixtures += $content
        }
        
        Write-Host "✓ $manufacturer - $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Hata: $($_.FullName)" -ForegroundColor Red
    }
}

Write-Host "`n📦 Toplam $($allFixtures.Count) fixture birleştiriliyor..." -ForegroundColor Cyan
$allFixtures | ConvertTo-Json -Depth 10 | Out-File "assets/fixtures/library_full.json" -Encoding UTF8
Write-Host "✅ Tamamlandı: library_full.json" -ForegroundColor Green
