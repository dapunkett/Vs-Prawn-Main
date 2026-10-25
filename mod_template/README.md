# NightmareVision Mod Template (base-game-main yapısı)

Bu mod şablonu, **NightmareVision Engine** içindeki ase-game-main yapısıyla birebir aynı hiyerarşide hazırlanmıştır.

## 📁 Dizin Hiyerarşisi
`
mod_template/
├── meta.json
├── data/
│   ├── characters/              # Karakter JSON ve scriptleri (.json / .hx)
│   ├── dialogue/                # Şarkı diyalog verileri
│   ├── events/                  # Chart olayları tanımları (.txt)
│   ├── notetypes/               # Özel nota türleri (.hx)
│   ├── scripts/                 # Global mod scriptleri (.hx)
│   ├── stages/<stageName>/      # data.json ve script.hx
│   ├── weeks/                   # Hafta tanımları (.json)
│   └── freeplay.json            # Freeplay sekme ve şarkı listesi
├── images/
│   ├── backgrounds/             # Sahne arkaplan görselleri
│   ├── characters/              # Karakter sprite ve XML dosyaları
│   ├── cutscenes/
│   ├── menus/
│   ├── pixelUI/
│   └── UI/
├── music/                       # Menü, game over müzikleri (.ogg)
├── shaders/                     # GLSL (.frag / .vert)
├── songs/<songName>/
│   ├── audio/ (Inst.ogg, Voices.ogg)
│   ├── charts/ (normal.json, events.json)
│   ├── meta.json
│   └── script.hx
└── sounds/                      # SFX sesleri (.ogg)
`
