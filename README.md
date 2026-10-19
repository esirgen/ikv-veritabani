# İnanır Kule Vinç - Saha Teknik Arşiv & Sürücü Teşhis Sistemi (v8.2)

Bu uygulama, **İnanır Kule Vinç** saha ve servis operasyonlarında kullanılmak üzere tasarlanmıştır. Telefonunuzun **Dosyalar (Files)** bölümündeki elektronik bağlantı şemalarını (PDF), galerinizdeki denge/karşı ağırlık şemalarını, resmi saha servis fişlerini ve 16 farklı inverter modeline ait arıza kodları ile parametrelerini içerir.

---

## 🛠️ v8.2 Sürüm Düzeltmeleri & Safari Çözümleri

### 1. "Renksiz Düz A4 Kağıt Gibi Açılma" Sorununun Çözümü:
- **Sorunun Nedeni:** Dosya Safari'de yerel dosya (`file:///`) olarak açıldığında veya internet bağlantısı zayıf olduğunda, harici CDN (`cdn.tailwindcss.com`) engelleniyor ve sayfa stilleri yüklenemiyordu.
- **Yapılan Düzeltme:** Tüm Tailwind CSS stilleri, karanlık tema renkleri (`#020617`, `#0f172a`, `#f59e0b`), grid/flex hizalamaları ve responsive kuralları doğrudan `index.html` içerisindeki `<style>` bloğuna gömülü (self-contained) hale getirildi. Artık internet veya harici CDN bağlantısı OLMADAN, uçak modunda dahi altın sarısı ve lacivert arayüz kusursuz açılır.

### 2. "Donma ve Hiçbir Şeyin Görünmemesi" Sorununun Çözümü:
- **Sorunun Nedeni:** İndirme fonksiyonundaki satır sonu kaçış hatası nedeniyle JavaScript motoru `SyntaxError` verip kilitleniyordu; bu yüzden `DOMContentLoaded` tetiklenmiyor ve markalar listelenemiyordu.
- **Yapılan Düzeltme:** JavaScript kodu Node.js motorunda derleme testlerinden (`node -c`) geçirilerek sıfır hata ile düzeltildi. Sayfa açılır açılmaz tüm markalar, inverterler ve servis fişleri anında listelenir.

---

## 📱 iPhone 17 Pro Max Kurulumu

1. ZIP içindeki `index.html` dosyasını telefonunuza kaydedin (örneğin Dosyalar > İndirilenler).
2. Dosyaya dokunarak Safari'de açın.
3. Safari ekranının altındaki **Paylaş (kare içinde yukarı ok)** simgesine dokunun.
4. **"Ana Ekrana Ekle"** seçeneğini seçip sağ üstteki **Ekle** butonuna basın.
5. Altın vinç logolu bağımsız bir iOS uygulaması olarak telefonunuza yerleşecek ve çevrimdışı çalışacaktır.

---

## 📁 Paket İçeriği

- `index.html`: %100 çevrimdışı, bağımsız çalışan kule vinç web uygulaması.
- `DataModel.json`: 17 kule vinç markası ve 16 inverter modelinin tam teknik veritabanı.
- `Kule_Vinc_Surucu_ve_Elektronik_Sema_Rehberi.pdf`: 21 sayfalık basılı teknik el kitabı.
- `InanirKuleVincApp.swift`: SwiftUI yerel iOS uygulama kaynak kodu.
- `README.md`: Kullanım ve teknik kılavuz.
