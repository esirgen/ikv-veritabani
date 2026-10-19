//
//  InanirKuleVincApp.swift
//  İnanır Kule Vinç - Saha ve Teknik Dokümantasyon Sistemi
//
//  Bu uygulama; kule vinç marka ve modellerine göre denge resimlerini,
//  elektronik bağlantı şemalarını (PDF & Görsel) ve arıza/elektronik kodlarını
//  çevrimdışı (offline) olarak kategorize edip şantiyede hızlı erişim sağlar.
//

import SwiftUI
import PDFKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Main Application Entry Point
@main
struct InanirKuleVincApp: App {
    @StateObject private var dataStore = CraneDataStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataStore)
                .preferredColorScheme(.dark) // Şantiyede ve sahada güneş altında yüksek kontrastlı endüstriyel tema
        }
    }
}

// MARK: - Models

enum MediaCategory: String, CaseIterable, Codable, Identifiable {
    case all = "Tümü"
    case balance = "Denge & Ağırlık"
    case electronic = "Elektronik Şemalar"
    case mechanical = "Mekanik & Kurulum"
    case general = "Genel Dokümanlar"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .balance: return "scalemass.fill"
        case .electronic: return "bolt.fill"
        case .mechanical: return "wrench.and.screwdriver.fill"
        case .general: return "doc.fill"
        }
    }
}

enum MediaFileType: String, Codable {
    case image = "Görsel"
    case pdf = "PDF"
    
    var iconName: String {
        switch self {
        case .image: return "photo.fill"
        case .pdf: return "doc.richtext.fill"
        }
    }
}

struct CraneMediaItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var category: MediaCategory
    var fileType: MediaFileType
    var localFileName: String // Documents dizinindeki dosya adı
    var notes: String
    var dateAdded: Date
    
    var fileURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(localFileName)
    }
}

enum ErrorSeverity: String, CaseIterable, Codable, Identifiable {
    case critical = "Kritik"
    case warning = "Uyarı"
    case info = "Bilgi"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct CraneErrorCode: Identifiable, Codable {
    var id = UUID()
    var code: String
    var title: String
    var description: String
    var possibleCause: String
    var solution: String
    var severity: ErrorSeverity
}

struct CraneModel: Identifiable, Codable {
    var id = UUID()
    var name: String
    var maxCapacityTons: Double
    var jibLengthMeters: Double
    var tipLoadTons: Double
    var description: String
    var mediaItems: [CraneMediaItem]
    var errorCodes: [CraneErrorCode]
}

struct CraneBrand: Identifiable, Codable {
    var id = UUID()
    var name: String
    var country: String
    var symbolIcon: String
    var models: [CraneModel]
}

// MARK: - Data Store (Local Storage & Persistence)

class CraneDataStore: ObservableObject {
    @Published var brands: [CraneBrand] = []
    @Published var searchQuery: String = ""
    
    private let saveKey = "InanirKuleVinc_BrandsData_v1"
    
    init() {
        loadData()
        if brands.isEmpty {
            loadInitialSeedData()
            saveData()
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(brands) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CraneBrand].self, from: data) {
            self.brands = decoded
        }
    }
    
    // Marka Ekle
    func addBrand(name: String, country: String, symbolIcon: String = "building.columns.fill") {
        let newBrand = CraneBrand(name: name, country: country, symbolIcon: symbolIcon, models: [])
        brands.append(newBrand)
        saveData()
    }
    
    // Model Ekle
    func addModel(to brandId: UUID, name: String, maxTons: Double, jibMeters: Double, tipTons: Double, desc: String) {
        guard let index = brands.firstIndex(where: { $0.id == brandId }) else { return }
        let newModel = CraneModel(
            name: name,
            maxCapacityTons: maxTons,
            jibLengthMeters: jibMeters,
            tipLoadTons: tipTons,
            description: desc,
            mediaItems: [],
            errorCodes: []
        )
        brands[index].models.append(newModel)
        saveData()
    }
    
    // Medya / Doküman Ekle (Dosyalar veya Galeriden kalıcı klasöre kopyalama)
    func addMediaItem(
        to brandId: UUID,
        modelId: UUID,
        title: String,
        category: MediaCategory,
        fileType: MediaFileType,
        sourceURL: URL,
        notes: String
    ) {
        guard let brandIdx = brands.firstIndex(where: { $0.id == brandId }),
              let modelIdx = brands[brandIdx].models.firstIndex(where: { $0.id == modelId }) else { return }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = sourceURL.pathExtension.isEmpty ? (fileType == .pdf ? "pdf" : "jpg") : sourceURL.pathExtension
        let uniqueName = "\(UUID().uuidString).\(ext)"
        let targetURL = docs.appendingPathComponent(uniqueName)
        
        // Kaynak dosyayı korumalı olarak Documents dizinine kopyala
        do {
            if sourceURL.startAccessingSecurityScopedResource() {
                defer { sourceURL.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: targetURL)
            } else {
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: targetURL)
            }
            
            let item = CraneMediaItem(
                title: title,
                category: category,
                fileType: fileType,
                localFileName: uniqueName,
                notes: notes,
                dateAdded: Date()
            )
            
            brands[brandIdx].models[modelIdx].mediaItems.append(item)
            saveData()
        } catch {
            print("Dosya kopyalama hatası: \(error.localizedDescription)")
        }
    }
    
    // Görsel Datasını Doğrudan Kaydet (Galeriden UIImage alındığında)
    func addImageFromData(
        to brandId: UUID,
        modelId: UUID,
        title: String,
        category: MediaCategory,
        imageData: Data,
        notes: String
    ) {
        guard let brandIdx = brands.firstIndex(where: { $0.id == brandId }),
              let modelIdx = brands[brandIdx].models.firstIndex(where: { $0.id == modelId }) else { return }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueName = "\(UUID().uuidString).jpg"
        let targetURL = docs.appendingPathComponent(uniqueName)
        
        do {
            try imageData.write(to: targetURL)
            let item = CraneMediaItem(
                title: title,
                category: category,
                fileType: .image,
                localFileName: uniqueName,
                notes: notes,
                dateAdded: Date()
            )
            brands[brandIdx].models[modelIdx].mediaItems.append(item)
            saveData()
        } catch {
            print("Görsel kaydetme hatası: \(error.localizedDescription)")
        }
    }
    
    // Arıza / Elektronik Kod Ekle
    func addErrorCode(
        to brandId: UUID,
        modelId: UUID,
        code: String,
        title: String,
        desc: String,
        cause: String,
        solution: String,
        severity: ErrorSeverity
    ) {
        guard let bIdx = brands.firstIndex(where: { $0.id == brandId }),
              let mIdx = brands[bIdx].models.firstIndex(where: { $0.id == modelId }) else { return }
        
        let newError = CraneErrorCode(
            code: code,
            title: title,
            description: desc,
            possibleCause: cause,
            solution: solution,
            severity: severity
        )
        brands[bIdx].models[mIdx].errorCodes.append(newError)
        saveData()
    }
    
    // Medya Sil
    func deleteMediaItem(brandId: UUID, modelId: UUID, itemId: UUID) {
        guard let bIdx = brands.firstIndex(where: { $0.id == brandId }),
              let mIdx = brands[bIdx].models.firstIndex(where: { $0.id == modelId }),
              let itemIdx = brands[bIdx].models[mIdx].mediaItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        let item = brands[bIdx].models[mIdx].mediaItems[itemIdx]
        if let url = item.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        brands[bIdx].models[mIdx].mediaItems.remove(at: itemIdx)
        saveData()
    }
    
    // İlk Kurulum Verileri (Örnek Marka, Model ve Tipik Arıza Kodları)
    private func loadInitialSeedData() {
        let potainMDT178 = CraneModel(
            name: "MDT 178",
            maxCapacityTons: 8.0,
            jibLengthMeters: 60.0,
            tipLoadTons: 1.5,
            description: "Topless seri kule vinç. Şehir içi ve kalabalık şantiyeler için optimize edilmiştir.",
            mediaItems: [],
            errorCodes: [
                CraneErrorCode(
                    code: "DTC 02",
                    title: "Rüzgar Hızı Sınır Aşımı (Anemometre)",
                    description: "Bom ucundaki rüzgar ölçer 72 km/s üzeri hız algıladı.",
                    possibleCause: "Fırtına, şiddetli rüzgar veya anemometre sensör kablo temassızlığı.",
                    solution: "Vinci hemen rüzgar serbestisine (fırdöndü) alın. Sensör konektörünü kontrol edin.",
                    severity: .critical
                ),
                CraneErrorCode(
                    code: "ERR 104",
                    title: "Kaldırma Motoru İnverter Aşırı Akım",
                    description: "Frekans invertörü nominal akımın 1.8 katını tespit etti.",
                    possibleCause: "Halat tamburunda sıkışma, mekanik fren bırakmama veya motor sargı izolasyon arızası.",
                    solution: "Fren açma bobini voltajını ölçün, motor sargı omik değerlerini test edin.",
                    severity: .critical
                ),
                CraneErrorCode(
                    code: "CAL 05",
                    title: "Yük Momenti Kalibrasyon Uyarısı",
                    description: "SLI (Safe Load Indicator) sıfır noktası sapması.",
                    possibleCause: "Pim tipi yük hücresi (load cell) mekanik kayması veya kablo gerilimi.",
                    solution: "Boş kanca ile dara kalibrasyonu yapın, test ağırlığı ile doğrulayın.",
                    severity: .warning
                )
            ]
        )
        
        let potainMC85 = CraneModel(
            name: "MC 85 B",
            maxCapacityTons: 5.0,
            jibLengthMeters: 52.0,
            tipLoadTons: 1.3,
            description: "Klasik kafes bomlu, orta ölçekli konut inşaatlarında yaygın kule vinç.",
            mediaItems: [],
            errorCodes: [
                CraneErrorCode(
                    code: "FLT 12",
                    title: "Dönüş Sınır Şalteri Devre Dışı",
                    description: "Kule dönüş tur sınırlayıcı mikro şalter sinyali gelmiyor.",
                    possibleCause: "Şalter dişli kutusu pimi kırık veya kablo kopukluğu.",
                    solution: "Kabin altındaki mekanik sayıcıyı kontrol edin, kabloları kontrol kalemiyle test edin.",
                    severity: .warning
                )
            ]
        )
        
        let liebherr280 = CraneModel(
            name: "280 EC-H 12 Litronic",
            maxCapacityTons: 12.0,
            jibLengthMeters: 75.0,
            tipLoadTons: 2.8,
            description: "Ağır sanayi, baraj ve yüksek gökdelen projeleri için Litronic kontrol sistemli vinç.",
            mediaItems: [],
            errorCodes: [
                CraneErrorCode(
                    code: "F-31",
                    title: "PLC CAN-Bus İletişim Hatası",
                    description: "Kabin ana kontrolörü ile kule dibi panosu arasında veri kesintisi.",
                    possibleCause: "Kule boyunca inen spiral CAN-Bus sinyal kablosunda zedelenme veya sonlandırma direnci arızası.",
                    solution: "Hat sonlandırma direncini (120 Ohm) ölçün. Döner bilezik (slip ring) fırçalarını temizleyin.",
                    severity: .critical
                ),
                CraneErrorCode(
                    code: "F-84",
                    title: "Şaryo (Trolley) Pozisyon Kodlayıcı Hatası",
                    description: "Bom üzerindeki encoder mutlak pozisyon bilgisini göndermiyor.",
                    possibleCause: "Optik enkoder tozu/nemi veya kaplin gevşemesi.",
                    solution: "Enkoder kaplin vidalarını sıkın, besleme voltajını (24V DC) teyit edin.",
                    severity: .warning
                )
            ]
        )
        
        let comansa21LC = CraneModel(
            name: "21LC290",
            maxCapacityTons: 18.0,
            jibLengthMeters: 74.0,
            tipLoadTons: 2.7,
            description: "Flat-top teknolojisiyle hızlı montaj ve hassas frekans kontrollü çalışma.",
            mediaItems: [],
            errorCodes: [
                CraneErrorCode(
                    code: "E-201",
                    title: "Dönüş Hidrolik Fren Basınç Düşüklüğü",
                    description: "Fren ünitesi hidrolik devresinde yetersiz basınç.",
                    possibleCause: "Hidrolik yağ seviyesi düşük veya selenoid valf tıkalı.",
                    solution: "Yağ tankı seviyesini kontrol edin ve filtreyi temizleyin.",
                    severity: .critical
                )
            ]
        )
        
        let zoomlionTC = CraneModel(
            name: "TC7035B",
            maxCapacityTons: 12.0,
            jibLengthMeters: 70.0,
            tipLoadTons: 3.5,
            description: "Yüksek yük momenti ve güçlü kaldırma mekanizmalı vinç.",
            mediaItems: [],
            errorCodes: []
        )
        
        self.brands = [
            CraneBrand(name: "Potain", country: "Fransa / Manitowoc", symbolIcon: "p.circle.fill", models: [potainMDT178, potainMC85]),
            CraneBrand(name: "Liebherr", country: "Almanya", symbolIcon: "l.circle.fill", models: [liebherr280]),
            CraneBrand(name: "Comansa", country: "İspanya", symbolIcon: "c.circle.fill", models: [comansa21LC]),
            CraneBrand(name: "Zoomlion", country: "Çin", symbolIcon: "z.circle.fill", models: [zoomlionTC]),
            CraneBrand(name: "Terex", country: "ABD / İtalya", symbolIcon: "t.circle.fill", models: []),
            CraneBrand(name: "Wolffkran", country: "Almanya", symbolIcon: "w.circle.fill", models: [])
        ]
    }
}

// MARK: - UI: Main Tab View

struct MainTabView: View {
    @EnvironmentObject var dataStore: CraneDataStore
    
    var body: some View {
        TabView {
            NavigationView {
                BrandsCatalogView()
            }
            .tabItem {
                Label("Katalog & Şemalar", systemImage: "building.2.crop.fill")
            }
            
            NavigationView {
                GlobalSearchAndCodesView()
            }
            .tabItem {
                Label("Arıza & Kod Arama", systemImage: "bolt.badge.clock.fill")
            }
            
            NavigationView {
                CompanyInfoView()
            }
            .tabItem {
                Label("İnanır Kule Vinç", systemImage: "info.circle.fill")
            }
        }
        .accentColor(Color(hex: "F59E0B")) // Sarı/Turuncu Kule Vinç Rengi
    }
}

// MARK: - UI: Brands Catalog View

struct BrandsCatalogView: View {
    @EnvironmentObject var dataStore: CraneDataStore
    @State private var showingAddBrandSheet = false
    @State private var searchBrandText = ""
    
    var filteredBrands: [CraneBrand] {
        if searchBrandText.isEmpty {
            return dataStore.brands
        } else {
            return dataStore.brands.filter {
                $0.name.localizedCaseInsensitiveContains(searchBrandText) ||
                $0.country.localizedCaseInsensitiveContains(searchBrandText) ||
                $0.models.contains { $0.name.localizedCaseInsensitiveContains(searchBrandText) }
            }
        }
    }
    
    var body: some View {
        List {
            // Şirket Başlık Kartı
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.title2)
                        Text("İNANIR KULE VİNÇ")
                            .font(.title3.weight(.black))
                            .foregroundColor(.white)
                        Spacer()
                        Text("SAHA SİSTEMİ")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F59E0B").opacity(0.25))
                            .foregroundColor(Color(hex: "F59E0B"))
                            .cornerRadius(6)
                    }
                    Text("Elektronik şemalar, denge diyagramları ve arıza kodları arşivine erişmek için marka seçin.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color(hex: "1F2937"))
            
            // Markalar Bölümü
            Section(header: Text("KULE VİNÇ MARKALARI (\(filteredBrands.count))").font(.caption.weight(.bold))) {
                ForEach(filteredBrands) { brand in
                    NavigationLink(destination: ModelsListView(brand: brand)) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "374151"))
                                    .frame(width: 48, height: 48)
                                Image(systemName: brand.symbolIcon)
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "F59E0B"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(brand.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(brand.country) • \(brand.models.count) Model Kayıtlı")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Doküman & Arıza Özeti Rozeti
                            let totalFiles = brand.models.reduce(0) { $0 + $1.mediaItems.count }
                            let totalErrors = brand.models.reduce(0) { $0 + $1.errorCodes.count }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                if totalFiles > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.fill")
                                        Text("\(totalFiles)")
                                    }
                                    .font(.caption2.bold())
                                    .foregroundColor(.orange)
                                }
                                if totalErrors > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("\(totalErrors)")
                                    }
                                    .font(.caption2.bold())
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $searchBrandText, prompt: "Marka veya model ara...")
        .navigationTitle("Markalar")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBrandSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "F59E0B"))
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddBrandSheet) {
            AddBrandSheet()
        }
    }
}

// MARK: - UI: Models List View

struct ModelsListView: View {
    @EnvironmentObject var dataStore: CraneDataStore
    let brand: CraneBrand
    @State private var showingAddModelSheet = false
    @State private var searchModelText = ""
    
    // Canlı güncellenen marka referansı
    var currentBrand: CraneBrand {
        dataStore.brands.first(where: { $0.id == brand.id }) ?? brand
    }
    
    var filteredModels: [CraneModel] {
        if searchModelText.isEmpty {
            return currentBrand.models
        } else {
            return currentBrand.models.filter {
                $0.name.localizedCaseInsensitiveContains(searchModelText) ||
                $0.description.localizedCaseInsensitiveContains(searchModelText)
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("\(currentBrand.name.uppercased()) MODELLERİ").font(.caption.bold())) {
                if filteredModels.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Bu markaya henüz model eklenmemiş.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("Yeni Model Ekle") {
                            showingAddModelSheet = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "F59E0B"))
                        .foregroundColor(.black)
                        .font(.footnote.bold())
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(filteredModels) { model in
                        NavigationLink(destination: ModelDetailView(brand: currentBrand, model: model)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(model.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(String(format: "%.1f", model.maxCapacityTons)) Ton")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "374151"))
                                        .foregroundColor(Color(hex: "F59E0B"))
                                        .cornerRadius(6)
                                }
                                
                                HStack(spacing: 16) {
                                    Label("\(String(format: "%.0f", model.jibLengthMeters))m Bom", systemImage: "ruler.fill")
                                    Label("\(String(format: "%.1f", model.tipLoadTons))t Uç Yükü", systemImage: "scalemass.fill")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                                
                                // Sayısal sayaç rozetleri
                                HStack(spacing: 12) {
                                    let balanceCount = model.mediaItems.filter { $0.category == .balance }.count
                                    let elecCount = model.mediaItems.filter { $0.category == .electronic }.count
                                    let totalDocs = model.mediaItems.count
                                    let errorCount = model.errorCodes.count
                                    
                                    BadgeView(title: "\(balanceCount) Denge", icon: "scalemass", color: .yellow)
                                    BadgeView(title: "\(elecCount) Şema", icon: "bolt", color: .blue)
                                    BadgeView(title: "\(totalDocs) Dosya", icon: "doc", color: .gray)
                                    BadgeView(title: "\(errorCount) Arıza", icon: "exclamationmark.triangle", color: .red)
                                }
                                .padding(.top, 2)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $searchModelText, prompt: "\(currentBrand.name) modellerinde ara...")
        .navigationTitle(currentBrand.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddModelSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
        .sheet(isPresented: $showingAddModelSheet) {
            AddModelSheet(brandId: currentBrand.id)
        }
    }
}

struct BadgeView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(5)
    }
}

// MARK: - UI: Model Detail View (Files, Schematics, Counterweights & Error Codes)

struct ModelDetailView: View {
    @EnvironmentObject var dataStore: CraneDataStore
    let brand: CraneBrand
    let model: CraneModel
    
    @State private var selectedTab: DetailTab = .schematics
    @State private var selectedCategoryFilter: MediaCategory = .all
    
    // İçe Aktarma Durumları
    @State private var showingFileImporter = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingAddErrorCodeSheet = false
    
    // Görüntüleyici Durumları
    @State private var activeMediaViewerItem: CraneMediaItem? = nil
    
    enum DetailTab: String, CaseIterable {
        case schematics = "Şemalar & Denge"
        case errorCodes = "Elektronik Kodlar"
        case specs = "Teknik Özellikler"
    }
    
    var currentModel: CraneModel {
        if let b = dataStore.brands.first(where: { $0.id == brand.id }),
           let m = b.models.first(where: { $0.id == model.id }) {
            return m
        }
        return model
    }
    
    var filteredMediaItems: [CraneMediaItem] {
        if selectedCategoryFilter == .all {
            return currentModel.mediaItems
        } else {
            return currentModel.mediaItems.filter { $0.category == selectedCategoryFilter }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Model Başlık Özeti
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(brand.name) - \(currentModel.name)")
                            .font(.title2.weight(.black))
                            .foregroundColor(.white)
                        Text("İnanır Kule Vinç Arşivi")
                            .font(.caption)
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Maks: \(String(format: "%.1f", currentModel.maxCapacityTons)) Ton")
                            .font(.footnote.bold())
                            .foregroundColor(.white)
                        Text("Bom: \(String(format: "%.0f", currentModel.jibLengthMeters))m")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Sekme Seçici
                Picker("Bölüm", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 6)
            }
            .padding()
            .background(Color(hex: "1F2937"))
            
            // Sekme İçerikleri
            switch selectedTab {
            case .schematics:
                schematicsAndBalanceSection
            case .errorCodes:
                errorCodesSection
            case .specs:
                specsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingFileImporter = true }) {
                        Label("Dosyalar'dan PDF / Belge Ekle", systemImage: "doc.badge.plus")
                    }
                    Button(action: { showingPhotoPicker = true }) {
                        Label("Galeriden Fotoğraf / Şema Ekle", systemImage: "photo.badge.plus")
                    }
                    Button(action: { showingAddErrorCodeSheet = true }) {
                        Label("Yeni Arıza / Elektronik Kod Ekle", systemImage: "bolt.badge.clock")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Ekle")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
        // PDF / Dosya İçe Aktarma
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.pdf, UTType.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                let isPDF = selectedURL.pathExtension.lowercased() == "pdf"
                dataStore.addMediaItem(
                    to: brand.id,
                    modelId: currentModel.id,
                    title: selectedURL.deletingPathExtension().lastPathComponent,
                    category: isPDF ? .electronic : .balance,
                    fileType: isPDF ? .pdf : .image,
                    sourceURL: selectedURL,
                    notes: "Dosyalar uygulamasından içe aktarıldı."
                )
            case .failure(let error):
                print("Dosya seçme başarısız: \(error.localizedDescription)")
            }
        }
        // Fotoğraf / Görsel Seçme
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        dataStore.addImageFromData(
                            to: brand.id,
                            modelId: currentModel.id,
                            title: "Saha Görseli \(Date().formatted(date: .numeric, time: .shortened))",
                            category: .balance,
                            imageData: data,
                            notes: "Galeriden içe aktarıldı."
                        )
                    }
                }
            }
        }
        // Kod Ekleme Sayfası
        .sheet(isPresented: $showingAddErrorCodeSheet) {
            AddErrorCodeSheet(brandId: brand.id, modelId: currentModel.id)
        }
        // Tam Ekran Görsel / PDF Görüntüleyici
        .fullScreenCover(item: $activeMediaViewerItem) { item in
            MediaDetailViewer(item: item)
        }
    }
    
    // MARK: - Şemalar ve Denge Resimleri Bölümü
    private var schematicsAndBalanceSection: some View {
        VStack(spacing: 0) {
            // Kategori Filtre Butonları (Yatay Kaydırma)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MediaCategory.allCases) { cat in
                        Button(action: { selectedCategoryFilter = cat }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.iconName)
                                Text(cat.rawValue)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategoryFilter == cat ? Color(hex: "F59E0B") : Color(hex: "374151"))
                            .foregroundColor(selectedCategoryFilter == cat ? .black : .white)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(hex: "111827"))
            
            // Dosya ve Görsel Listesi / Izgarası
            if filteredMediaItems.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 56))
                        .foregroundColor(.gray)
                    Text("Bu kategoride kayıtlı şema veya görsel yok.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Sağ üstteki + 'Ekle' butonuna basarak Dosyalar bölümündeki PDF'leri veya galerinizdeki denge resimlerini ekleyebilirsiniz.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    HStack(spacing: 16) {
                        Button(action: { showingFileImporter = true }) {
                            Label("PDF Şema Ekle", systemImage: "doc.badge.plus")
                                .font(.footnote.bold())
                                .padding()
                                .background(Color(hex: "374151"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: { showingPhotoPicker = true }) {
                            Label("Fotoğraf Ekle", systemImage: "photo.badge.plus")
                                .font(.footnote.bold())
                                .padding()
                                .background(Color(hex: "F59E0B"))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(filteredMediaItems) { item in
                            MediaItemCard(item: item) {
                                activeMediaViewerItem = item
                            } onDelete: {
                                dataStore.deleteMediaItem(brandId: brand.id, modelId: currentModel.id, itemId: item.id)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Arıza Kodları Bölümü
    private var errorCodesSection: some View {
        List {
            Section(header: Text("KODLAR & ARIZA REHBERİ (\(currentModel.errorCodes.count))").font(.caption.bold())) {
                if currentModel.errorCodes.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Bu modele ait henüz kayıtlı arıza kodu yok.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Button("+ Yeni Kod Ekle") {
                            showingAddErrorCodeSheet = true
                        }
                        .font(.footnote.bold())
                        .foregroundColor(Color(hex: "F59E0B"))
                    }
                    .padding(.vertical, 16)
                } else {
                    ForEach(currentModel.errorCodes) { err in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(err.code)
                                    .font(.headline.weight(.black))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "F59E0B").opacity(0.15))
                                    .cornerRadius(6)
                                
                                Text(err.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(err.severity.rawValue)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(err.severity.color.opacity(0.2))
                                    .foregroundColor(err.severity.color)
                                    .cornerRadius(4)
                            }
                            
                            Text(err.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("Olası Neden:")
                                        .font(.caption2.bold())
                                        .foregroundColor(.orange)
                                    Text(err.possibleCause)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                HStack(alignment: .top) {
                                    Text("Çözüm Adımı:")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)
                                    Text(err.solution)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(8)
                            .background(Color(hex: "1F2937"))
                            .cornerRadius(6)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Teknik Özellikler Bölümü
    private var specsSection: some View {
        List {
            Section(header: Text("KULE VİNÇ TEKNİK BİLGİLERİ").font(.caption.bold())) {
                SpecRow(label: "Maksimum Kaldırma Kapasitesi", value: "\(String(format: "%.1f", currentModel.maxCapacityTons)) Ton", icon: "scalemass.fill")
                SpecRow(label: "Maksimum Bom Uzunluğu", value: "\(String(format: "%.0f", currentModel.jibLengthMeters)) Metre", icon: "ruler.fill")
                SpecRow(label: "Bom Ucu Kaldırma Kapasitesi", value: "\(String(format: "%.1f", currentModel.tipLoadTons)) Ton", icon: "arrow.down.to.line.compact")
                SpecRow(label: "Üretici Firma", value: brand.name, icon: "building.2.fill")
                SpecRow(label: "Menşei", value: brand.country, icon: "globe")
            }
            
            Section(header: Text("MODEL NOTLARI").font(.caption.bold())) {
                Text(currentModel.description.isEmpty ? "Bu model için özel not girilmemiş." : currentModel.description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct SpecRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "F59E0B"))
                .frame(width: 24)
            Text(label)
                .font(.footnote)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.footnote.bold())
                .foregroundColor(Color(hex: "F59E0B"))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - UI: Media Item Card (Dosya / Resim Önizleme Kartı)

struct MediaItemCard: View {
    let item: CraneMediaItem
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Önizleme Alanı
                if item.fileType == .image, let url = item.fileURL, let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else if item.fileType == .pdf {
                    ZStack {
                        Color(hex: "1F2937")
                            .frame(height: 120)
                        VStack(spacing: 8) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text("PDF ŞEMA")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    ZStack {
                        Color(hex: "1F2937")
                            .frame(height: 120)
                        Image(systemName: "photo.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                
                // Kategori Rozeti (Üst Sol)
                HStack {
                    Text(item.category.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(6)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onOpen()
            }
            
            // Alt Bilgi Alanı
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(item.fileType.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            .padding(8)
            .background(Color(hex: "374151"))
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - UI: Full Screen Media Viewer (PDF & Image with Zoom)

struct MediaDetailViewer: View {
    @Environment(\.dismiss) var dismiss
    let item: CraneMediaItem
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if item.fileType == .pdf, let url = item.fileURL {
                    PDFKitRepresentable(url: url)
                        .edgesIgnoringSafeArea(.bottom)
                } else if item.fileType == .image, let url = item.fileURL, let uiImage = UIImage(contentsOfFile: url.path) {
                    ZoomableImageView(image: uiImage)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Dosya yüklenemedi veya bulunamadı.")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "F59E0B"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = item.fileURL {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                        .sheet(isPresented: $showingShareSheet) {
                            ActivityView(activityItems: [url])
                        }
                    }
                }
            }
        }
    }
}

// PDFKit SwiftUI Entegrasyonu
struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(url: url)
        }
    }
}

// Pinch to Zoom (Çift Parmak Yakınlaştırma) Görsel Görüntüleyici
struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, min(lastScale * value, 5.0))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.5
                            lastScale = 2.5
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// Dosya Paylaşım Sheet'i
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - UI: Global Search & Error Codes Finder

struct GlobalSearchAndCodesView: View {
    @EnvironmentObject var dataStore: CraneDataStore
    @State private var searchCodeText = ""
    @State private var selectedSeverityFilter: ErrorSeverity? = nil
    
    var allErrorsWithContext: [(brand: CraneBrand, model: CraneModel, error: CraneErrorCode)] {
        var results: [(CraneBrand, CraneModel, CraneErrorCode)] = []
        for brand in dataStore.brands {
            for model in brand.models {
                for error in model.errorCodes {
                    results.append((brand, model, error))
                }
            }
        }
        return results
    }
    
    var filteredResults: [(brand: CraneBrand, model: CraneModel, error: CraneErrorCode)] {
        allErrorsWithContext.filter { item in
            let matchesText = searchCodeText.isEmpty ||
                item.error.code.localizedCaseInsensitiveContains(searchCodeText) ||
                item.error.title.localizedCaseInsensitiveContains(searchCodeText) ||
                item.error.possibleCause.localizedCaseInsensitiveContains(searchCodeText) ||
                item.model.name.localizedCaseInsensitiveContains(searchCodeText) ||
                item.brand.name.localizedCaseInsensitiveContains(searchCodeText)
            
            let matchesSeverity = (selectedSeverityFilter == nil) || (item.error.severity == selectedSeverityFilter)
            return matchesText && matchesSeverity
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("ARIZA KODU & TEŞHİS FİLTRESİ").font(.caption.bold())) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Şantiyede panelde veya kumandada gördüğünüz hata kodunu (örn. DTC 02, F-31, ERR 104) yazarak doğrudan çözüm adımlarına ulaşabilirsiniz.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button("Tümü") {
                            selectedSeverityFilter = nil
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedSeverityFilter == nil ? Color(hex: "F59E0B") : Color(hex: "374151"))
                        .foregroundColor(selectedSeverityFilter == nil ? .black : .white)
                        .cornerRadius(6)
                        
                        ForEach(ErrorSeverity.allCases) { sev in
                            Button(sev.rawValue) {
                                selectedSeverityFilter = sev
                            }
                            .font(.caption2.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedSeverityFilter == sev ? sev.color : Color(hex: "374151"))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("BULUNAN ARIZA KODLARI (\(filteredResults.count))").font(.caption.bold())) {
                if filteredResults.isEmpty {
                    Text("Aramanıza uygun hata kodu bulunamadı.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(filteredResults, id: \.error.id) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(item.brand.name) \(item.model.name)")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(item.error.severity.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.error.severity.color.opacity(0.2))
                                    .foregroundColor(item.error.severity.color)
                                    .cornerRadius(4)
                            }
                            
                            HStack {
                                Text(item.error.code)
                                    .font(.title3.weight(.black))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text(item.error.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text(item.error.description)
                                .font(.footnote)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Olası Sebep: \(item.error.possibleCause)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Müdahale & Çözüm: \(item.error.solution)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "1F2937"))
                            .cornerRadius(6)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .searchable(text: $searchCodeText, prompt: "Kod no, arıza adı veya model yazın...")
        .navigationTitle("Arıza Teşhis")
    }
}

// MARK: - UI: Company Information & Contact View

struct CompanyInfoView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F59E0B").opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                    
                    Text("İNANIR KULE VİNÇ")
                        .font(.title2.weight(.black))
                        .foregroundColor(.white)
                    
                    Text("Kule Vinç Kiralama, Montaj, Demontaj, Servis ve Teknik Bakım Hizmetleri")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color(hex: "1F2937"))
            
            Section(header: Text("UYGULAMA KAPASİTESİ VE VERİLER").font(.caption.bold())) {
                HStack {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .foregroundColor(.green)
                    Text("Çevrimdışı (Offline) Saha Desteği")
                    Spacer()
                    Text("Aktif")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.blue)
                    Text("Veri Saklama")
                    Spacer()
                    Text("Yerel / Cihaz İçi")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                HStack {
                    Image(systemName: "doc.viewfinder.fill")
                        .foregroundColor(.orange)
                    Text("Desteklenen Belgeler")
                    Spacer()
                    Text("PDF & Yüksek Çözünürlüklü Görsel")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("KULLANIM KILAVUZU").font(.caption.bold())) {
                VStack(alignment: .leading, spacing: 8) {
                    GuideBullet(step: "1", text: "Katalog bölümünden çalıştığınız kule vincin markasını ve modelini seçin.")
                    GuideBullet(step: "2", text: "Sağ üst köşedeki '+' menüsünden telefonunuzun Dosyalar uygulamasındaki elektronik şema PDF'lerini veya fotoğraf galerinizdeki denge resimlerini modele yükleyin.")
                    GuideBullet(step: "3", text: "İçe aktarılan tüm belgeler telefonun yerel hafızasına kaydedilir; şantiyede internet olmadan da açılır ve çift parmakla yakınlaştırılabilir.")
                    GuideBullet(step: "4", text: "Arıza Kodları sekmesinden panoda yanan kodları girerek arıza çözümlerini hızlıca bulun.")
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Hakkında")
    }
}

struct GuideBullet: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(step)
                .font(.caption2.bold())
                .frame(width: 20, height: 20)
                .background(Color(hex: "F59E0B"))
                .foregroundColor(.black)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

// MARK: - UI: Sheets (Add Brand, Add Model, Add Error Code)

struct AddBrandSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: CraneDataStore
    
    @State private var name: String = ""
    @State private var country: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MARKA BİLGİLERİ").font(.caption.bold())) {
                    TextField("Marka Adı (Örn: Saez, Jaso, Raimondi)", text: $name)
                    TextField("Üretim Ülkesi (Örn: İspanya, İtalya)", text: $country)
                }
            }
            .navigationTitle("Yeni Marka Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            dataStore.addBrand(name: name, country: country.isEmpty ? "Belirtilmemiş" : country)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
    }
}

struct AddModelSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: CraneDataStore
    let brandId: UUID
    
    @State private var name: String = ""
    @State private var maxTons: String = "8.0"
    @State private var jibMeters: String = "60"
    @State private var tipTons: String = "1.5"
    @State private var desc: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MODEL DETAYLARI").font(.caption.bold())) {
                    TextField("Model Adı (Örn: MDT 219, 150 EC-B)", text: $name)
                    HStack {
                        Text("Maks Kapasite (Ton):")
                            .font(.footnote)
                        Spacer()
                        TextField("Ton", text: $maxTons)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Bom Uzunluğu (m):")
                            .font(.footnote)
                        Spacer()
                        TextField("Metre", text: $jibMeters)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Bom Ucu Yükü (Ton):")
                            .font(.footnote)
                        Spacer()
                        TextField("Ton", text: $tipTons)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("AÇIKLAMA VEYA KURULUM NOTU").font(.caption.bold())) {
                    TextEditor(text: $desc)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Yeni Model Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            dataStore.addModel(
                                to: brandId,
                                name: name,
                                maxTons: Double(maxTons.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                                jibMeters: Double(jibMeters.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                                tipTons: Double(tipTons.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                                desc: desc
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
    }
}

struct AddErrorCodeSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: CraneDataStore
    let brandId: UUID
    let modelId: UUID
    
    @State private var code: String = ""
    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var cause: String = ""
    @State private var solution: String = ""
    @State private var severity: ErrorSeverity = .critical
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("KOD TANIMI").font(.caption.bold())) {
                    TextField("Hata / Arıza Kodu (Örn: E-04, F-12)", text: $code)
                    TextField("Arıza Başlığı (Örn: Rüzgar Aşırı Hız Sensörü)", text: $title)
                    Picker("Kritiklik Seviyesi", selection: $severity) {
                        ForEach(ErrorSeverity.allCases) { sev in
                            Text(sev.rawValue).tag(sev)
                        }
                    }
                }
                
                Section(header: Text("AÇIKLAMA").font(.caption.bold())) {
                    TextField("Panoda veya ekranda görülen durum", text: $desc)
                }
                
                Section(header: Text("OLASI SEBEPLER").font(.caption.bold())) {
                    TextField("Olası nedenler (kablo, şalter, röle vb.)", text: $cause)
                }
                
                Section(header: Text("SAHADA MÜDAHALE & ÇÖZÜM ADIMI").font(.caption.bold())) {
                    TextEditor(text: $solution)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Yeni Arıza Kodu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if !code.trimmingCharacters(in: .whitespaces).isEmpty {
                            dataStore.addErrorCode(
                                to: brandId,
                                modelId: modelId,
                                code: code,
                                title: title.isEmpty ? "Genel Hata" : title,
                                desc: desc,
                                cause: cause,
                                solution: solution,
                                severity: severity
                            )
                            dismiss()
                        }
                    }
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
    }
}

// MARK: - Color Extension (Hex Renk Desteği)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}