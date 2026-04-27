const fs = require('fs');
const path = require('path');

function getAllJsonFiles(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory()) {
            getAllJsonFiles(filePath, fileList);
        } else if (file.endsWith('.json') && file !== 'library.json' && file !== 'library_full.json') {
            fileList.push(filePath);
        }
    });
    
    return fileList;
}

function mergeFixtures() {
    const fixturesDir = 'assets/fixtures';
    const allFixtures = [];
    
    const jsonFiles = getAllJsonFiles(fixturesDir);
    console.log(`📦 ${jsonFiles.length} JSON dosyası bulundu`);
    
    let successCount = 0;
    let errorCount = 0;
    
    jsonFiles.forEach(filePath => {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const data = JSON.parse(content);
            
            if (data.name && data.channels) {
                allFixtures.push(data);
                successCount++;
            } else if (Array.isArray(data)) {
                data.forEach(item => {
                    if (item.name && item.channels) {
                        allFixtures.push(item);
                        successCount++;
                    }
                });
            }
        } catch (e) {
            errorCount++;
        }
    });
    
    // Alfabetik sırala
    allFixtures.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    
    // Yaz
    const outputPath = path.join(fixturesDir, 'library_full.json');
    fs.writeFileSync(outputPath, JSON.stringify(allFixtures, null, 2), 'utf8');
    
    console.log(`✅ ${successCount} cihaz birleştirildi`);
    console.log(`⚠️ ${errorCount} hatalı dosya atlandı`);
    console.log(`📄 Dosya: ${outputPath}`);
    
    return successCount;
}

try {
    const count = mergeFixtures();
    console.log(`\n🎉 Toplam: ${count} cihaz`);
} catch (e) {
    console.error('❌ Hata:', e.message);
}
