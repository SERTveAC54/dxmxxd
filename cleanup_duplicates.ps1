# Duplicate Fixture Klasörlerini Temizleme Script'i
# Bu script boşluklu klasörleri siler, sadece alt çizgili olanları bırakır

Write-Host "🧹 Duplicate klasörler temizleniyor..." -ForegroundColor Cyan

$fixturesPath = "assets\fixtures"

# Silinecek klasörler (boşluklu olanlar)
$foldersToDelete = @(
    "American DJ",
    "Blizzard Lighting",
    "Chauvet DJ",
    "Chauvet Professional",
    "Clay Paky",
    "Color Imagination",
    "Dia Lighting",
    "Dune Lighting",
    "Eliminator Lighting",
    "Event Lighting",
    "Flash Professional",
    "FOS Technologies",
    "Fractal Lights",
    "Fun Generation",
    "German Light Products",
    "GLX Lighting",
    "High End Systems",
    "Hive Lighting",
    "Hong Yi",
    "HQ Power",
    "Ibiza light",
    "IMG Stageline",
    "JB Systems",
    "Kino Flo",
    "LIGHT SKY",
    "Light Emotion",
    "Look Solutions",
    "Mac Mah",
    "Mega LED Lighting",
    "Minuit Une",
    "Optima Lighting",
    "Orion Effects Lighting",
    "Phocea Light",
    "Power Lighting",
    "PR LIGHTING",
    "Philips Selecon",
    "Robert Juliat",
    "Silver Star",
    "Smoke Factory",
    "Stage Right",
    "Stellar Labs",
    "Studio Due",
    "Sun Star",
    "TIPTOP Stage Light",
    "Triton Blue",
    "Big Dipper"
)

$deletedCount = 0
$notFoundCount = 0

foreach ($folder in $foldersToDelete) {
    $fullPath = Join-Path $fixturesPath $folder
    
    if (Test-Path $fullPath) {
        Write-Host "🗑️  Siliniyor: $folder" -ForegroundColor Yellow
        Remove-Item $fullPath -Recurse -Force
        $deletedCount++
    } else {
        Write-Host "⏭️  Bulunamadı: $folder" -ForegroundColor Gray
        $notFoundCount++
    }
}

Write-Host ""
Write-Host "✅ Temizlik tamamlandı!" -ForegroundColor Green
Write-Host "   Silinen: $deletedCount klasör" -ForegroundColor Green
Write-Host "   Bulunamayan: $notFoundCount klasör" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 Kalan klasörler (alt çizgili):" -ForegroundColor Cyan
Write-Host "   - American_DJ" -ForegroundColor White
Write-Host "   - Clay_Paky" -ForegroundColor White
Write-Host "   - Eliminator_Lighting" -ForegroundColor White
Write-Host "   - Event_Lighting" -ForegroundColor White
Write-Host "   - JB_Systems" -ForegroundColor White
Write-Host "   - Look_Solutions" -ForegroundColor White
Write-Host "   - Orion_Effects_Lighting" -ForegroundColor White
Write-Host "   - Robert_Juliat" -ForegroundColor White
Write-Host "   - Smoke_Factory" -ForegroundColor White
Write-Host "   - Stage_Right" -ForegroundColor White
Write-Host "   - Studio_Due" -ForegroundColor White
Write-Host "   ... ve diğerleri" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Şimdi uygulamayı test edebilirsiniz!" -ForegroundColor Green
