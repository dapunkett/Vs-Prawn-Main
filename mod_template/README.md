# NightmareVision Engine - Mod Template

Bu klasör, **NightmareVision Engine** (Vs Prawn) için hazırlanmış örnek mod şablonudur.
Kendi modunu oluşturmak için bu klasörü kopyalayabilir veya adını değiştirip içerisindeki dosyaları düzenleyebilirsin.

---

## 📁 Klasör Yapısı ve Kullanımı

### 1. `meta.json`
Modun ana ayar ve bilgi dosyasıdır.
- `name`: Mod listesinde ve başlıkta görünecek mod ismi.
- `description`: Modun açıklaması.
- `global`: `true` yapılırsa, diğer modlarla beraber arka planda her zaman aktif kalır.
- `windowTitle`: Oyun penceresinin başlığı.
- `iconFile`: Modun özel pencere ikonu (`UI/icon64`).
- `defaultTransition`: Geçiş animasyonu (örn: `"swipe"`, `"fade"`).

---

### 2. `weeks/` (Haftalar / Story Mode & Freeplay)
- `template-week.json`: Haftanın şarkılarını, arka planını, karakterlerini ve zorluklarını tanımlar.
  - `storyName`: Hikaye modundaki adı.
  - `difficulties`: Geçerli zorluk seviyeleri (örn: `"Easy, Normal, Hard"`).
  - `songs`: `[["şarkı-adı", "karakter-icon", [R, G, B]]]`.
  - `weekCharacters`: Story mode menüsünde duracak karakterler `[rakip, bf, gf]`.

---

### 3. `songs/` (Şarkılar, Notlar ve Müzikler)
Her şarkının kendine ait bir alt klasörü olmalıdır: `songs/<şarkı-adı>/`
- `meta.json`: Şarkının görünen adı, bestecileri (`composers`), charter bilgileri (`charters`), Freeplay menü rengi (`freeplayColor`) ve ikonu (`freeplayIcon`).
- `script.hx`: Şarkıya özel HScript kodları (kamera hareketleri, özel eventler, mekanikler).
- `audio/`:
  - `Inst.ogg`: Şarkının enstrümantal müziği.
  - `Voices.ogg`: Şarkının vokal müziği.
- `charts/`:
  - `normal.json`: Normal zorluktaki nota grafiği (chart).
  - `easy.json`, `hard.json`: İsteğe bağlı diğer zorluk grafikleri.
  - `events.json`: Şarkı içerisindeki kamera sallanması, flash vb. olaylar.

---

### 4. `characters/` (Karakterler)
- `template-character.json`: Karakterin sprite dosya yolu (`image`), can ikonu (`healthicon`), animasyonları (`animations`), ofsetleri (`offsets`), can barı renkleri (`healthbar_colors`) ve kamera pozisyonu (`camera_position`).
- Karakter sprite'ları (`.png` ve `.xml`) `images/characters/` klasörüne yerleştirilir.

---

### 5. `stages/` (Sahneler)
- `template-stage.json`: Karakterlerin sahnede duracağı koordinatlar (`boyfriend`, `opponent`, `girlfriend`), sahne varsayılan yakınlaştırması (`defaultZoom`) ve `hide_girlfriend` ayarı.
- `template-stage.hxs`: Sahnede çalışan HScript dosyası. `onLoad()`, `onUpdate(elapsed)`, `onBeatHit()` gibi fonksiyonlarla sahne elemanları yönetilebilir.

---

### 6. `custom_events/` (Özel Eventler)
Chart editöründen tetiklenebilen özel olayların açıklamaları (`.txt`) veya scriptleri (`.hx` / `.lua`).
Örnekler:
- `Camera Flash.txt`
- `Screen Shake.txt`

---

### 7. `data/` (Veriler)
- `freeplay.json`: Freeplay menüsünde özel sekmeler (tabs) oluşturmak ve şarkıları gruplamak için kullanılır.

---

### 8. `images/`, `sounds/`, `music/`, `fonts/`, `shaders/`
- `images/`: Sahne arkaplanları, karakterler ve UI grafikleri.
- `sounds/`: Menü ses efektleri, tıklama sesleri.
- `music/`: Menü fon müzikleri, game over müzikleri.
- `fonts/`: Özel fontlar (`.ttf`, `.otf`).
- `shaders/`: Özel GLSL grafik shader dosyaları (`.frag`, `.vert`).

---

## 🚀 Modu Aktif Etme
1. Bu klasörü `content/` dizinine yerleştir.
2. Oyunu başlat ve Ana Menü'den **Mods** menüsüne gir.
3. Modunu listeden seçip **Etkinleştir** (Enable).
