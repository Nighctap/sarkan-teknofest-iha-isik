"""
Ana Uygulama - İHA Görüntü İşleme ve Kontrol Sistemi
"""

import cv2
import yaml
import argparse
from pathlib import Path
from loguru import logger
from datetime import datetime

from src.core.sensor_manager import CameraManager, PixhawkManager
from src.vision.color_filter import ColorFilter
from src.vision.target_detector import TargetDetector
from src.decision.decision_engine import DecisionEngine, TourType
from src.localization.map_manager import MapManager


class UAVSystem:
    """Ana İHA sistem sınıfı"""

    def __init__(self, config_path: str):
        """
        Sistem başlatma

        Args:
            config_path: Konfigürasyon dosyası yolu
        """
        # Konfigürasyonu yükle
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)

        # Loglama ayarları
        self._setup_logging()

        # Bileşenleri başlat
        self.camera = CameraManager(self.config)
        self.pixhawk = PixhawkManager(self.config)
        self.color_filter = ColorFilter(self.config)
        self.target_detector = TargetDetector(self.config)
        self.decision_engine = DecisionEngine(self.config)
        self.map_manager = MapManager(self.config)

        # Durum değişkenleri
        self.current_tour = None
        self.target_color = None
        self.running = False

    def _setup_logging(self):
        """Loglama sistemini ayarla"""
        log_config = self.config['logging']

        if log_config['save_logs']:
            log_dir = Path(log_config['log_dir'])
            log_dir.mkdir(exist_ok=True)

            log_file = log_dir / f"uav_system_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
            logger.add(log_file, level=log_config['level'])

        logger.info("Loglama sistemi başlatıldı")

    def initialize(self) -> bool:
        """Tüm bileşenleri başlat"""
        logger.info("Sistem başlatılıyor...")

        # Kamera başlat
        if not self.camera.initialize():
            logger.error("Kamera başlatılamadı")
            return False

        # Pixhawk bağlantısı (opsiyonel - simülasyon modu için)
        if self.config['sensors']['pixhawk']['connection_string']:
            if not self.pixhawk.initialize():
                logger.warning("Pixhawk bağlantısı kurulamadı - Simülasyon modunda devam ediliyor")

        # YOLO modeli yükle (eğer kullanılacaksa)
        if self.config['image_processing']['tour_detection']['enabled']:
            if not self.target_detector.initialize():
                logger.warning("YOLO modeli yüklenemedi")

        logger.info("Sistem başarıyla başlatıldı")
        return True

    def set_tour(self, tour_type: TourType, target_color: str = None):
        """
        Tur tipini ayarla

        Args:
            tour_type: Tur tipi (TUR_1 veya TUR_2)
            target_color: Hedef rengi (TUR_1 için: 'red', 'green', 'blue')
        """
        self.current_tour = tour_type
        self.target_color = target_color
        self.decision_engine.set_tour_type(tour_type)

        logger.info(f"Tur ayarlandı: {tour_type.name}, Renk: {target_color}")

    def process_tour_1(self, frame):
        """
        1. Tur işleme - Renk filtresi tabanlı

        Args:
            frame: Kameradan gelen görüntü

        Returns:
            İşlenmiş frame ve tespit sonucu
        """
        if self.target_color is None:
            logger.error("Hedef renk ayarlanmamış")
            return frame, None

        # Renk filtresi ile hedef tespiti
        detection = self.color_filter.process_frame(frame, self.target_color)

        if detection:
            # Tespit sonucunu çiz
            frame = self.color_filter.draw_detection(frame, detection)

        return frame, detection

    def process_tour_2(self, frame):
        """
        2. Tur işleme - Sensör tabanlı (GPS/IMU + Görüntü işleme)

        Args:
            frame: Kameradan gelen görüntü

        Returns:
            İşlenmiş frame ve tespit sonucu
        """
        # YOLO ile hedef tespiti
        detections = self.target_detector.detect(frame)

        if detections:
            # Tespitleri çiz
            frame = self.target_detector.draw_detections(frame, detections)

            # En iyi hedefi seç
            best_target = self.target_detector.get_best_target(detections)
            return frame, best_target

        return frame, None

    def run(self):
        """Ana döngü"""
        self.running = True
        frame_count = 0

        logger.info("Ana döngü başlatıldı")

        try:
            while self.running:
                # Frame oku
                frame = self.camera.read_frame()
                if frame is None:
                    logger.warning("Frame okunamadı")
                    continue

                # Sensör verilerini güncelle
                self.pixhawk.update_telemetry()
                gps_data = self.pixhawk.get_gps_coordinates()
                altitude = self.pixhawk.get_altitude()
                attitude = self.pixhawk.get_attitude()

                # Görüntü işleme (tur tipine göre)
                if self.current_tour == TourType.TUR_1:
                    processed_frame, detection = self.process_tour_1(frame)
                elif self.current_tour == TourType.TUR_2:
                    processed_frame, detection = self.process_tour_2(frame)
                else:
                    processed_frame = frame
                    detection = None
                    logger.warning("Tur tipi ayarlanmamış")

                # Karar mekanizması
                sensor_data = {
                    'gps': gps_data,
                    'altitude': altitude,
                    'attitude': attitude
                }

                decision = self.decision_engine.process_decision(detection, sensor_data)

                # Ateş kararı
                if decision['can_fire']:
                    logger.info("ATEŞ ETME KOMUTU!")
                    self.fire_weapon()

                # Harita güncelleme
                if gps_data and frame_count % 10 == 0:  # Her 10 frame'de bir
                    coords = (gps_data['lat'], gps_data['lon'])
                    self.map_manager.add_trajectory_point(coords, altitude)

                    if detection:
                        self.map_manager.add_target_location(
                            coords,
                            'target',
                            detection.get('confidence', 1.0)
                        )

                # Bilgi overlay
                self._draw_overlay(processed_frame, sensor_data, decision)

                # Görüntüyü göster
                cv2.imshow('UAV System', processed_frame)

                # Kayıt (opsiyonel)
                if self.config['logging']['save_images'] and frame_count % 30 == 0:
                    self._save_frame(processed_frame, frame_count)

                frame_count += 1

                # Çıkış kontrolü
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q'):
                    logger.info("Kullanıcı çıkış yaptı")
                    break
                elif key == ord('1'):
                    self.set_tour(TourType.TUR_1, 'red')
                elif key == ord('2'):
                    self.set_tour(TourType.TUR_2)

        except KeyboardInterrupt:
            logger.info("Keyboard interrupt - Sistem kapatılıyor")

        finally:
            self.cleanup()

    def fire_weapon(self):
        """Ateş mekanizmasını tetikle"""
        fire_config = self.config['firing_system']

        if not fire_config['enabled']:
            logger.warning("Ateş sistemi devre dışı")
            return

        servo_channel = fire_config['servo_channel']
        fire_duration = fire_config['fire_duration']

        # Servo komutunu gönder (PWM 1900 = ateş)
        self.pixhawk.send_servo_command(servo_channel, 1900)
        logger.info(f"ATEŞ EDİLDİ! Kanal: {servo_channel}")

        # Kısa bir süre sonra servo'yu eski konumuna getir
        import time
        time.sleep(fire_duration / 1000.0)
        self.pixhawk.send_servo_command(servo_channel, 1500)

    def _draw_overlay(self, frame, sensor_data, decision):
        """Görüntü üzerine bilgi ekle"""
        h, w = frame.shape[:2]

        # Arka plan
        overlay = frame.copy()
        cv2.rectangle(overlay, (10, 10), (400, 150), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.5, frame, 0.5, 0, frame)

        # Metin bilgileri
        texts = []

        if sensor_data['gps']:
            gps = sensor_data['gps']
            texts.append(f"GPS: {gps['lat']:.6f}, {gps['lon']:.6f}")
            texts.append(f"Alt: {sensor_data['altitude']:.1f}m")

        texts.append(f"Status: {decision['target_status']}")

        if decision['can_fire']:
            texts.append(">>> FIRE READY <<<")

        # Metinleri çiz
        y_offset = 30
        for text in texts:
            cv2.putText(frame, text, (20, y_offset),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
            y_offset += 25

        # Hedef işareti (ekran merkezi)
        cx, cy = w // 2, h // 2
        cv2.line(frame, (cx - 20, cy), (cx + 20, cy), (0, 255, 0), 2)
        cv2.line(frame, (cx, cy - 20), (cx, cy + 20), (0, 255, 0), 2)
        cv2.circle(frame, (cx, cy), 30, (0, 255, 0), 2)

    def _save_frame(self, frame, frame_num):
        """Frame'i kaydet"""
        image_dir = Path(self.config['logging']['image_dir'])
        image_dir.mkdir(parents=True, exist_ok=True)

        filename = image_dir / f"frame_{frame_num:06d}.jpg"
        cv2.imwrite(str(filename), frame)

    def cleanup(self):
        """Kaynakları temizle"""
        logger.info("Sistem kapatılıyor...")

        self.camera.release()
        self.pixhawk.close()
        cv2.destroyAllWindows()

        # Haritayı kaydet
        log_dir = Path(self.config['logging']['log_dir'])
        log_dir.mkdir(exist_ok=True)

        map_file = log_dir / f"map_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        self.map_manager.update_map()
        self.map_manager.save_map(str(map_file))

        trajectory_file = log_dir / f"trajectory_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        self.map_manager.save_trajectory_json(str(trajectory_file))

        # İstatistikler
        stats = self.map_manager.get_statistics()
        logger.info(f"İstatistikler: {stats}")

        logger.info("Sistem kapatıldı")


def main():
    """Ana fonksiyon"""
    parser = argparse.ArgumentParser(description='İHA Görüntü İşleme ve Kontrol Sistemi')
    parser.add_argument('--config', type=str, default='config.yaml',
                       help='Konfigürasyon dosyası yolu')
    parser.add_argument('--tour', type=int, choices=[1, 2], default=1,
                       help='Tur tipi (1: Renk filtresi, 2: Sensör tabanlı)')
    parser.add_argument('--color', type=str, choices=['red', 'green', 'blue'],
                       default='red', help='Hedef rengi (Tur 1 için)')

    args = parser.parse_args()

    # Sistem oluştur ve başlat
    system = UAVSystem(args.config)

    if not system.initialize():
        logger.error("Sistem başlatılamadı")
        return

    # Tur tipini ayarla
    tour_type = TourType.TUR_1 if args.tour == 1 else TourType.TUR_2
    target_color = args.color if args.tour == 1 else None
    system.set_tour(tour_type, target_color)

    # Sistemi çalıştır
    system.run()


if __name__ == '__main__':
    main()
