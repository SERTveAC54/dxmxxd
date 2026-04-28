import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Eğer uuid paketin yoksa pubspec.yaml'a eklemelisin: uuid: ^4.2.1
import '../services/fixture_manager.dart';
import '../models/fixture.dart';

class PatchScreen extends StatelessWidget {
  const PatchScreen({super.key});

  // --- MANUEL FİKSTÜR OLUŞTURMA PENCERESİ ---
  void _showManualFixtureBuilder(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Manuel Fikstür",
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ManualFixtureDialog(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<FixtureManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Column(
          children: [
            // --- ÜST BAŞLIK VE BUTONLAR ---
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF10121A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PATCH & FİKSTÜRLER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Toplam ${manager.patchedFixtures.length} cihaz eklendi (Universe 1)", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      // KÜTÜPHANEDEN EKLE BUTONU
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        icon: const Icon(Icons.library_books, size: 20),
                        label: const Text("KÜTÜPHANEDEN", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          // TODO: Kütüphane sayfasına yönlendir
                        },
                      ),
                      const SizedBox(width: 16),
                      // MANUEL EKLE BUTONU (YENİ)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.build, size: 20),
                        label: const Text("MANUEL OLUŞTUR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        onPressed: () => _showManualFixtureBuilder(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // --- CİHAZ LİSTESİ TABLOSU ---
            Expanded(
              child: manager.patchedFixtures.isEmpty 
              ? const Center(child: Text("Sahneye henüz cihaz eklenmedi.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: manager.patchedFixtures.length,
                  itemBuilder: (context, index) {
                    final fixture = manager.patchedFixtures[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151822),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.lightbulb, color: Color(0xFF00E5FF)),
                        ),
                        title: Text(fixture.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("${fixture.manufacturer} - ${fixture.channelCount} Kanal", style: const TextStyle(color: Colors.white54)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(
                            "DMX: ${fixture.startAddress}", 
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------
// MANUEL CİHAZ OLUŞTURMA DİYALOĞU (GELİŞMİŞ)
// -----------------------------------------------------------------
class ManualFixtureDialog extends StatefulWidget {
  const ManualFixtureDialog({super.key});

  @override
  State<ManualFixtureDialog> createState() => _ManualFixtureDialogState();
}

class _ManualFixtureDialogState extends State<ManualFixtureDialog> {
  final TextEditingController _nameController = TextEditingController(text: "Yeni Robot");
  final TextEditingController _addressController = TextEditingController(text: "1");
  final TextEditingController _channelCountController = TextEditingController(text: "4");

  // Kullanıcının oluşturduğu kanalların listesi
  List<ChannelData> _channels = [];

  // Sık kullanılan kanal tipleri (Dropdown için)
  final List<String> _commonTypes = ["Dimmer", "Red", "Green", "Blue", "White", "Pan", "Tilt", "Strobe", "Macro", "Other"];

  @override
  void initState() {
    super.initState();
    _generateChannels(4); // Varsayılan 4 kanal oluştur
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _channelCountController.dispose();
    super.dispose();
  }

  // Kanal sayısı değiştikçe listeyi güncelleyen fonksiyon
  void _generateChannels(int count) {
    if (count <= 0 || count > 512) return;
    
    List<ChannelData> newChannels = [];
    for (int i = 0; i < count; i++) {
      // Eğer mevcut listede varsa eski değerini koru, yoksa yeni oluştur
      if (i < _channels.length) {
        newChannels.add(_channels[i]);
      } else {
        newChannels.add(ChannelData(name: "Kanal ${i + 1}", typeName: "Other"));
      }
    }
    setState(() {
      _channels = newChannels;
    });
  }

  // String olan tipi senin Fixture modelindeki 'ChannelType' enum'una güvenli çevirir
  ChannelType _getSafeEnum(String typeStr) {
    final searchStr = typeStr.toLowerCase();
    for (var val in ChannelType.values) {
      if (val.toString().split('.').last.toLowerCase() == searchStr) {
        return val;
      }
    }
    // Eğer eşleşen enum yoksa, listedeki ilk enum'u güvenli şekilde döndür (Örn: ChannelType.other)
    return ChannelType.values.last; 
  }

  void _saveFixture() {
    final manager = context.read<FixtureManager>();
    
    // Girilen verileri doğrula
    int startAddress = int.tryParse(_addressController.text) ?? 1;
    if (startAddress < 1 || startAddress > 512) startAddress = 1;

    // Kanal objelerini senin sistemine göre oluştur
    List<FixtureChannel> mappedChannels = [];
    for (int i = 0; i < _channels.length; i++) {
      mappedChannels.add(
        FixtureChannel(
          offset: i, // 0'dan başlar
          name: _channels[i].name,
          type: _getSafeEnum(_channels[i].typeName),
        )
      );
    }

    // Yeni Fikstürü Oluştur
    final newFixture = Fixture(
      id: const Uuid().v4(), // Rastgele eşsiz ID üretir
      name: _nameController.text.isEmpty ? "İsimsiz Cihaz" : _nameController.text,
      manufacturer: "Manuel", // Manuel oluşturulan cihazlar için
      channelCount: _channels.length,
      startAddress: startAddress,
      channels: mappedChannels,
    );

    // TODO: Burada senin manager içindeki ekleme fonksiyonunu çağır.
    // Örneğin: manager.addFixture(newFixture);
    // Şu an elimizde metodun tam adını bilmediğimiz için listeye ekleyip widget'ı güncelliyoruz.
    manager.patchedFixtures.add(newFixture);
    // Eğer manager'da notifyListeners() tetiklenmesi için özel bir add() metodu varsa yukarıdaki satırı onunla değiştir.

    Navigator.pop(context); // Diyaloğu kapat
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFF151822),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, spreadRadius: 10)],
      ),
      child: Column(
        children: [
          // DİYALOG BAŞLIĞI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF10121A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("MANUEL FİKSTÜR OLUŞTUR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // ÜST AYARLAR (İsim, DMX, Kanal Sayısı)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField("Cihaz Adı", _nameController, TextInputType.text),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTextField("DMX Adres", _addressController, TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    "Kanal Sayısı", 
                    _channelCountController, 
                    TextInputType.number,
                    onChanged: (val) {
                      int? count = int.tryParse(val);
                      if (count != null) _generateChannels(count);
                    }
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // KANAL YAPILANDIRMA LİSTESİ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11131A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // Kanal Numarası
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                        child: Text("CH\n${index + 1}", style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 16),
                      
                      // Kanal Tipi Seçimi (Dropdown)
                      Expanded(
                        flex: 1,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF151822),
                            value: _channels[index].typeName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            items: _commonTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                            }).toList(),
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() { _channels[index].typeName = newType; });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Kanal Özel Adı (İsteğe bağlı)
                      Expanded(
                        flex: 2,
                        child: TextField(
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Örn: Master Dimmer",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => _channels[index].name = val,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // KAYDET BUTONU
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF10121A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveFixture,
                child: const Text("CİHAZI SAHNEYE EKLE (PATCH)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          )

        ],
      ),
    );
  }

  // Ortak TextField Tasarımı
  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, {Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
      ],
    );
  }
}

// Dialog içinde kanalların geçici verilerini tutan ufak model
class ChannelData {
  String name;
  String typeName;
  ChannelData({required this.name, required this.typeName});
}