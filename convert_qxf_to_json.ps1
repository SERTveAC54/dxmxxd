# QXF (QLC+ XML) dosyalarini JSON'a cevir ve birlestir
$allFixtures = @()

# Once JSON dosyalarini ekle
Write-Host "JSON dosyalari yukleniyor..." -ForegroundColor Cyan
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
    } catch {}
}

Write-Host "OK: $($allFixtures.Count) JSON fixture yuklendi" -ForegroundColor Green

# Simdi QXF dosyalarini parse et
Write-Host "`nQXF dosyalari parse ediliyor..." -ForegroundColor Cyan
$qxfCount = 0

Get-ChildItem -Path "assets/fixtures" -Recurse -Filter "*.qxf" | ForEach-Object {
    try {
        $manufacturer = $_.Directory.Name
        [xml]$xml = Get-Content $_.FullName -Raw
        
        $fixtureName = $xml.FixtureDefinition.Model
        if (-not $fixtureName) { $fixtureName = $_.BaseName }
        
        $channels = @()
        
        # QXF Channel parsing
        foreach ($channel in $xml.FixtureDefinition.Channel) {
            $channelName = $channel.Name
            if ($channelName) {
                $channels += $channelName
            }
        }
        
        # Eger kanal bulunamazsa Mode'dan dene
        if ($channels.Count -eq 0) {
            $mode = $xml.FixtureDefinition.Mode | Select-Object -First 1
            if ($mode.Channel) {
                foreach ($ch in $mode.Channel) {
                    if ($ch.Number -ne $null) {
                        $chName = $ch.InnerText
                        if (-not $chName) { $chName = "Channel $($ch.Number)" }
                        $channels += $chName
                    }
                }
            }
        }
        
        if ($channels.Count -gt 0) {
            $fixture = [PSCustomObject]@{
                name = $fixtureName
                manufacturer = $manufacturer
                channels = $channels
            }
            
            $allFixtures += $fixture
            $qxfCount++
            
            if ($qxfCount % 100 -eq 0) {
                Write-Host "  -> $qxfCount QXF islendi..." -ForegroundColor Yellow
            }
        }
        
    } catch {
        # Sessizce devam et
    }
}

Write-Host "OK: $qxfCount QXF fixture parse edildi" -ForegroundColor Green
Write-Host "`nToplam $($allFixtures.Count) fixture birlestiriliyor..." -ForegroundColor Cyan

$allFixtures | ConvertTo-Json -Depth 10 -Compress | Out-File "assets/fixtures/library_full.json" -Encoding UTF8

Write-Host "TAMAM: library_full.json ($($allFixtures.Count) fixture)" -ForegroundColor Green
