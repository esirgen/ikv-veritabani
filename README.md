# 🏗️ İnanır Kule Vinç - Saha Arşiv & Sürücü Teşhis Sistemi (GitHub Pages)

Bu depo, **İnanır Kule Vinç** şantiye ve saha operasyonları için geliştirilmiş **PWA (Progressive Web App)** tabanlı teknik arşiv, resmi servis fişi düzenleme ve sürücü (inverter) teşhis sistemidir.

GitHub Pages üzerinde **tamamen ücretsiz, sıfır sunucu maliyetiyle ve 7/24 kesintisiz** çalışır.

---

## 🚀 3 Adımda GitHub Pages ile Canlıya Alma (Kurulum)

Hiçbir kodlama veya terminal bilgisine gerek yoktur. Web tarayıcınızdan 2 dakikada yayına alabilirsiniz:

### 1. Adım: GitHub'da Yeni Depo (Repository) Açın
1. [GitHub.com](https://github.com) hesabınıza giriş yapın (hesabınız yoksa ücretsiz kaydolun).
2. Sağ üstteki **+** simgesine tıklayıp **"New repository"** seçin.
3. Repository name kısmına örneğin **`inanir-vinc`** veya **`saha`** yazın.
4. Görünürlüğü **Public** (Herkese Açık) seçin.
5. Alttaki yeşil **"Create repository"** butonuna basın.

### 2. Adım: Dosyaları Yükleyin
1. Açılan boş repository sayfasında **"uploading an existing file"** linkine tıklayın.
2. Bu klasördeki dosyaları (özellikle **`index.html`**, **`.nojekyll`**, **`manifest.json`**, **`inanir_kule_vinc_icon.png`**) tarayıcıya sürükleyip bırakın.
3. Sayfanın altındaki yeşil **"Commit changes"** butonuna basın.

### 3. Adım: GitHub Pages'i Aktif Edin (1 Tıkla Yayın)
1. Deponuzun üst menüsündeki **"Settings" (Ayarlar)** sekmesine tıklayın.
2. Sol menüden **"Pages"** başlığını seçin.
3. **Build and deployment > Branch** kısmında:
   - `None` yazan yeri **`main`** (veya `master`) olarak seçin.
   - Klasör olarak **`/(root)`** seçin.
4. **"Save" (Kaydet)** butonuna tıklayın.

🎉 **Tebrikler!** 1-2 dakika içinde sayfanın üstünde yeşil kutuda canlı web adresiniz belirecektir:
> **`https://<kullanici-adiniz>.github.io/<repo-adiniz>/`**  
> *(Örnek: `https://ahmetinanir.github.io/inanir-vinc/`)*

---

## 📲 Çalışanlara ve iPhone'a Kurulum (Safari Yöntemi)

Canlı linkinizi 5 saha çalışanınıza WhatsApp'tan gönderin. Her çalışan kendi telefonunda:

1. Linke **Safari** tarayıcısında dokunup açar.
2. Alt araç çubuğundaki **Paylaş** (kare ve yukarı ok) simgesine dokunur.
3. Menüyü kaydırıp **"Ana Ekrana Ekle" (Add to Home Screen)** seçeneğini seçer.
4. Sağ üstteki **"Ekle"** butonuna basar.

Artık telefonun ana ekranında özel **İnanır Kule Vinç** ikonu yer alır. Dokunulduğunda Safari adres çubukları gizlenir, tam ekran bir iPhone uygulaması olarak açılır ve **şantiyede internet çekmese dahi %100 çevrimdışı (offline)** çalışır.

---

## 🌟 Sistem Özellikleri

- **🏗️ 10 Kule Vinç Markası & Modelleri:** Potain, Liebherr, Comansa, Zoomlion, Jaso, Towerwork, FM Gru, Dahan, Raimondi, Saez, Terex vb.
- **🎛️ 9 Büyük İnverter Teşhis Kütüphanesi:** Sinee EM730/EM760, Schneider ATV71/ATV340/ATV320, Inovance CS710/MD500/HD92, Mitsubishi FR-A800/A700, Omron Varispeed F7, Yaskawa A1000, KEB F5, Siemens G120, ABB ACS880, Danfoss FC302, Fuji Frenic.
  - **362+ Fabrika Arıza Kodu:** Olası nedenler ve sahada kesin çözüm adımları.
  - **445+ Kritik Parametre:** Vinç güvenlik mantığı, fabrika değeri ve olması gereken çalışma değerleri.
- **📋 Resmi Servis & Müdahale Formu:** Şantiyede yapılan montaj, demontaj, arıza ve periyodik bakımları A4 formatında yazdırma veya WhatsApp üzerinden tek tıkla resmi rapor gönderme.
- **🔢 Makine Seri No Kütüğü & Fotoğraflı Şecere:** Kule vincin seri numarasını yazarak bugüne kadar yapılan tüm tamirleri, değişen parçaları ve çekilen saha fotoğraflarını tarih sırasıyla görme.
- **👥 Canlı Ekip (Online) Senkronizasyonu:** Patron ve 5 çalışan arasında tek bir şirket anahtarıyla (Sync Key) veri eşitleme.
- **💾 Yerel & Güvenli Depolama:** Yüklenen fotoğraflar, şemalar ve fişler cihazın güvenli hafızasında (`localStorage` / `IndexedDB`) saklanır, JSON olarak dışa aktarılabilir.

---

## 📁 Depo Dosya Yapısı

```text
├── index.html                  # Tüm uygulamanın çalıştığı ana PWA tek sayfa uygulaması
├── .nojekyll                   # GitHub Pages'in özel dosyaları filtrelemesini engelleyen kural
├── manifest.json               # Mobil cihazlar için PWA uygulama manifestosu
├── inanir_kule_vinc_icon.png   # 512x512 iOS & Android uygulama ikonu
├── inanir_kule_vinc_icon.svg   # Vektörel kule vinç simgesi
├── inanir_kule_vinc_logo.svg   # Şirket antet vektör logosu
├── DataModel.json              # Ham marka, model ve sürücü veritabanı (Yedek)
├── company_settings.json       # Varsayılan firma antet ayarları
└── README.md                   # Bu rehber dokümanı
```

---

## 🏢 İletişim & Destek
**İnanır Kule Vinç San. ve Tic. Ltd. Şti.**  
Saha Teknik Arşiv & Sürücü Teşhis Merkezi  
