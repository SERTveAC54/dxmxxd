import json
import os
from pathlib import Path

def merge_all_fixtures():
    fixtures_dir = Path("assets/fixtures")
    all_fixtures = []
    
    # Tüm JSON dosyalarını tara
    json_files = list(fixtures_dir.rglob("*.json"))
    
    print(f"📦 {len(json_files)} JSON dosyası bulundu")
    
    for json_file in json_files:
        # library.json ve diğer özel dosyaları atla
        if json_file.name in ["library.json", "library_full.json", "FixturesMap.xml"]:
            continue
            
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            # Eğer fixture formatında ise ekle
            if isinstance(data, dict) and 'name' in data and 'channels' in data:
                all_fixtures.append(data)
            elif isinstance(data, list):
                # Array ise her birini ekle
                for item in data:
                    if isinstance(item, dict) and 'name' in item and 'channels' in item:
                        all_fixtures.append(item)
                        
        except Exception as e:
            print(f"⚠️ Hata ({json_file.name}): {e}")
            continue
    
    # Alfabetik sırala
    all_fixtures.sort(key=lambda x: x.get('name', ''))
    
    # Yeni dosyaya yaz
    output_file = fixtures_dir / "library_full.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_fixtures, f, indent=2, ensure_ascii=False)
    
    print(f"✅ {len(all_fixtures)} cihaz birleştirildi: {output_file}")
    return len(all_fixtures)

if __name__ == "__main__":
    count = merge_all_fixtures()
    print(f"\n🎉 Toplam: {count} cihaz")
