# İHA Görüntü İşleme ve Kontrol Sistemi

Teknofest İHA Yarışması için geliştirilmiş görüntü işleme ve otonom kontrol sistemi.

## Sistem Mimarisi

### 1. Donanım Bileşenleri
- **Sensör Grubu**: Kamera (3088p/720p) + Pixhawk/Hava Hızı sensörleri
- **Uçuş Bilgisayarı**: Görüntü işleme ve karar mekanizması
- **Uçuş Kontrol Kartı**: Pixhawk/Cube (MAVLink protokolü)
- **Yer Kontrol İstasyonu**: Harita gösterimi ve lokalizasyon

### 2. Yazılım Modülleri

#### Core Modülleri (`src/core/`)
- **CameraManager**: Kamera yönetimi ve görüntü yakalama
- **PixhawkManager**: MAVLink ile uçuş kontrol kartı iletişimi

#### Görüntü İşleme (`src/vision/`)
- **ColorFilter**: HSV renk filtresi ile hedef algılama (Kırmızı/Yeşil/Mavi)
- **TargetDetector**: YOLOv8 tabanlı hedef tespiti

#### Karar Mekanizması (`src/decision/`)
- **DecisionEngine**: Sensör ve görüntü verilerini birleştirerek karar verme
- **BallisticCalculator**: Balistik hesaplama ve ateş çözümü

#### Lokalizasyon (`src/localization/`)
- **MapManager**: GPS koordinatları ve trajectory takibi

## Kurulum

### 1. Virtual Environment Oluşturma
```bash
cd görüntü-isleme-modeli
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Bağımlılıkları Yükleme
```bash
pip install -r requirements.txt
```

### 3. YOLO Model İndirme
```bash
# YOLOv8 modeli otomatik indirilecek veya manuel:
mkdir models
# YOLOv8n modelini models/ klasörüne koyun
```

## Kullanım

### Temel Kullanım
```bash
# Tur 1 (Renk Filtresi - Kırmızı hedef)
python main.py --tour 1 --color red

# Tur 2 (Sensör Tabanlı + YOLO)
python main.py --tour 2
```

### Konfigürasyon
`config.yaml` dosyasından tüm parametreler ayarlanabilir:
- Kamera ayarları
- Renk filtresi eşik değerleri
- YOLO model parametreleri
- Balistik hesaplama parametreleri
- Loglama ve kayıt ayarları

### Klavye Kısayolları
- **1**: Tur 1'e geç (Renk filtresi - Kırmızı)
- **2**: Tur 2'ye geç (Sensör tabanlı)
- **Q**: Çıkış

## Algoritma Akışı

### Tur 1: Renk Filtresi Tabanlı
1. Kameradan görüntü al
2. HSV renk uzayına dönüştür
3. Hedef renge göre filtrele (Kırmızı/Yeşil/Mavi)
4. Morfolojik işlemler (gürültü temizleme)
5. Kontur tespiti
6. Piksel ve GPS koordinatlarını birleştir
7. Hedef ölçüm kontrolü
8. **EVET**: Balistik hesaplama → Ateşleme
9. **HAYIR**: GPS koordinat ayarla ve devam et

### Tur 2: Sensör Tabanlı
1. Kameradan görüntü al
2. Sensör verilerini oku (GPS/IMU/Altitude)
3. YOLO ile hedef tespiti
4. Hedefin merkezli olma kontrolü
5. Balistik hesaplama (rüzgar, hız vb.)
6. Bırakma persentaj kontrolü
7. **EVET**: Ateşleme
8. **HAYIR**: Servo kontrolü ve MAVLink paket ayarla

## Pixhawk Bağlantısı

### MAVLink Bağlantı Seçenekleri
```yaml
# Serial bağlantı
connection_string: "COM3"  # Windows
connection_string: "/dev/ttyACM0"  # Linux

# UDP (SITL simülasyon)
connection_string: "udp:127.0.0.1:14550"

# TCP
connection_string: "tcp:192.168.1.100:5760"
```

## Çıktılar

### Log Dosyaları
- `logs/uav_system_YYYYMMDD_HHMMSS.log`: Detaylı sistem logları
- `logs/images/frame_XXXXXX.jpg`: Kaydedilmiş görüntü kareleri

### Harita Dosyaları
- `logs/map_YYYYMMDD_HHMMSS.html`: İnteraktif HTML haritası
- `logs/trajectory_YYYYMMDD_HHMMSS.json`: GPS trajectory verisi

## Geliştirme

### Proje Yapısı
```
görüntü-isleme-modeli/
├── src/
│   ├── core/           # Temel bileşenler
│   ├── vision/         # Görüntü işleme
│   ├── decision/       # Karar mekanizması
│   └── localization/   # Harita ve GPS
├── models/             # Makine öğrenmesi modelleri
├── logs/               # Log ve kayıt dosyaları
├── config.yaml         # Konfigürasyon
├── main.py             # Ana uygulama
└── requirements.txt    # Bağımlılıklar
```

### Yeni Modül Ekleme
1. İlgili klasörde yeni Python dosyası oluştur
2. `__init__.py` dosyasını güncelle
3. `main.py` içinde modülü import et ve entegre et

## Sorun Giderme

### Kamera Açılmıyor
- Kamera bağlantısını kontrol edin
- `config.yaml` içinde `camera.source` değerini değiştirin (0, 1, 2...)

### Pixhawk Bağlantı Hatası
- Bağlantı string'ini kontrol edin
- Serial port izinlerini kontrol edin (Linux)
- SITL simülasyonu için MAVProxy'yi başlatın

### YOLO Modeli Yüklenmiyor
- `models/yolov8n.pt` dosyasının varlığını kontrol edin
- İnternet bağlantısı varsa otomatik indirilecektir

## Lisans

SARKAN Takımı - Teknofest İHA Yarışması

## Katkıda Bulunanlar

- Görüntü İşleme Modülü
- Uçuş Kontrol Sistemi
- Karar Mekanizması
- Test ve Entegrasyon
