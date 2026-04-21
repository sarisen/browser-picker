# Browser Picker - macOS için Kural Tabanlı URL Yönlendirici

<p align="center">
  <img src="docs/logo.png" alt="Browser Picker logo" width="160">
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

Tıkladığınız her linki otomatik olarak doğru tarayıcıya yönlendiren hafif bir macOS menü çubuğu uygulaması.

Linki hangi uygulamanın açtığını ve hangi domaine gittiğini temel alan kurallar tanımlarsınız. Browser Picker bunları öncelik sırasıyla değerlendirip ilk eşleşeni açar — seçtiğiniz tarayıcıda, isterseniz gizli modda veya yeni pencerede.

[İndir](#i̇ndir) · [Özellikler](#özellikler) · [Nasıl Çalışır](#nasıl-çalışır) · [Derleme](#yerel-derleme)

---

## İndir

En son DMG dosyasını [releases sayfasından](../../releases/latest) indirin.

1. DMG'yi açın ve **Browser Picker**'ı Applications klasörüne sürükleyin.
2. macOS güvenlik uyarısı gösterirse şu komutu çalıştırın:
   ```
   xattr -c /Applications/BrowserPicker.app
   ```
3. Browser Picker'ı başlatın — Dock'ta değil, menü çubuğunda görünür.

---

## Özellikler

- Tanımladığınız kurallara göre linkleri farklı tarayıcılara yönlendirin
- Kaynak uygulama (linki açan uygulama), domain deseni veya her ikisiyle eşleştirin
- Domain eşleştirme; tam hostname, joker karakter (`*.github.com`) ve tam regex destekler
- Eşleşen linkleri gizli / özel modda veya yeni pencerede açın
- Üçüncü taraf bağımlılığı sıfır — güncelleme çerçevesi yok, telemetri yok
- Konfigürasyon `~/.config/browserpicker/config.json` adresinde düz JSON olarak saklanır

---

## Nasıl Çalışır

1. Sistem Ayarları'nda Browser Picker'ı varsayılan tarayıcı olarak ayarlarsınız.
2. Herhangi bir uygulama `http` veya `https` linki açtığında macOS bunu Browser Picker'a iletir.
3. Browser Picker linki hangi uygulamanın gönderdiğini ve URL'nin hostname'ini kontrol eder.
4. Kurallar önceliğe göre sıralanır; tüm koşulları eşleşen ilk kural kazanır.
5. Kazanan tarayıcı URL'yi açar — gerekirse gizli mod veya yeni pencere bayrağıyla.
6. Hiçbir kural eşleşmezse link, Browser Picker içinde ayarladığınız varsayılan tarayıcıda açılır.

---

## İlk Kurulum

1. DMG'den yükleyin ve uygulamayı açın.
2. Menü çubuğu ikonuna tıklayın ve **Settings** (⌘,) açın.
3. General sekmesindeki **Set Default** butonuna tıklayarak Browser Picker'ı sistem varsayılan tarayıcısı olarak kaydedin.
4. **Rules** sekmesine geçin ve ilk kuralınızı ekleyin.
5. Her kural için kaynak uygulama, domain deseni ve hedef tarayıcıyı belirleyin.

---

## Proje Yapısı

```text
browser-picker/
├── BrowserPicker/
│   ├── BrowserPickerApp.swift   — uygulama giriş noktası
│   ├── AppDelegate.swift        — URL yakalama, yönlendirme
│   ├── AppTracker.swift         — aktif uygulamayı takip eder (@MainActor)
│   ├── PickerConfig.swift       — veri modelleri
│   ├── Router.swift             — kural değerlendirme motoru
│   ├── ConfigStore.swift        — JSON config dosyası I/O
│   ├── Scanners.swift           — kurulu tarayıcı ve uygulama tespiti
│   ├── BrowserOpener.swift      — tarayıcıları doğru parametrelerle başlatır
│   ├── AppLog.swift             — yapılandırılmış loglama
│   ├── MenuBarIcon.swift        — menü çubuğu için özel template image
│   ├── MenuBarView.swift        — menü çubuğu açılır menüsü
│   ├── SettingsView.swift       — ayarlar penceresi (Rules / General sekmeleri)
│   ├── RuleRowView.swift        — kural düzenleyici satır bileşeni
│   └── AboutView.swift          — hakkında ekranı
├── BrowserPickerTests/
│   ├── RouterTests.swift        — kural motoru testleri (25 test)
│   ├── URLMatcherTests.swift    — domain eşleştirme testleri (18 test)
│   ├── AppMatcherTests.swift    — kaynak uygulama eşleştirme testleri (9 test)
│   └── ConfigTests.swift        — config encode/decode testleri
├── scripts/
│   └── build-release-dmg.sh    — release DMG oluşturur
├── docs/
│   └── logo.png
└── generate_icon.swift          — AppIcon PNG boyutlarını üretir
```

---

## Gereksinimler

- macOS 14.0 veya üzeri
- Xcode 15 veya üzeri (kaynak koddan derlemek için)

---

## Yerel Derleme

```bash
git clone https://github.com/sarisen/browser-picker.git
cd browser-picker
open BrowserPicker.xcodeproj
```

Komut satırından:

```bash
make build   # Debug derleme
make test    # Tüm testleri çalıştır
make install # Derle ve /Applications'a kopyala
```

Etiketli sürümler GitHub Actions aracılığıyla otomatik olarak derlenir ve yayınlanır.

---

## Lisans

MIT.
