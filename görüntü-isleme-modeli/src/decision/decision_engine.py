"""
Karar Motoru
Sensör verileri ve görüntü işleme sonuçlarını birleştirerek karar verir
"""

import numpy as np
from typing import Dict, Any, Optional
from loguru import logger
from dataclasses import dataclass
from enum import Enum


class TourType(Enum):
    """Tur tipi"""
    TUR_1 = 1  # Renk filtresi tabanlı
    TUR_2 = 2  # Sensör tabanlı


class TargetStatus(Enum):
    """Hedef durumu"""
    SEARCHING = "searching"
    DETECTED = "detected"
    LOCKED = "locked"
    LOST = "lost"


@dataclass
class TargetInfo:
    """Hedef bilgisi"""
    center: tuple
    area: float
    confidence: float
    distance: Optional[float] = None
    angle: Optional[float] = None
    status: TargetStatus = TargetStatus.DETECTED


class BallisticCalculator:
    """Balistik hesaplama modülü"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.wind_speed = config['image_processing']['ballistics']['ruzgar_hizi']
        self.speed_critical = config['image_processing']['ballistics']['hiz_kritik']
        self.percentage_threshold = config['image_processing']['ballistics']['percentage_threshold']

    def calculate_firing_solution(
        self,
        target_distance: float,
        target_angle: float,
        wind_speed: float,
        altitude: float
    ) -> Dict[str, Any]:
        """
        Balistik hesaplama yap

        Args:
            target_distance: Hedefe mesafe (m)
            target_angle: Hedef açısı (derece)
            wind_speed: Rüzgar hızı (m/s)
            altitude: İrtifa (m)

        Returns:
            Ateş çözümü parametreleri
        """
        # Basitleştirilmiş balistik model
        # Gerçek uygulamada daha detaylı hesaplamalar gerekir

        # Rüzgar kompanzasyonu
        wind_compensation = wind_speed * 0.1  # Basit bir model

        # Yerçekimi düşüşü
        gravity_drop = 9.81 * (target_distance / 100) ** 2

        # Hedef liderlik (moving target için)
        lead_angle = 0.0  # Statik hedef varsayımı

        # Kritik mesafe kontrolü
        in_range = target_distance <= self.percentage_threshold * 100  # Örnek maksimum menzil

        solution = {
            'distance': target_distance,
            'angle': target_angle,
            'wind_compensation': wind_compensation,
            'gravity_drop': gravity_drop,
            'lead_angle': lead_angle,
            'in_range': in_range,
            'can_fire': in_range and self.speed_critical
        }

        return solution


class DecisionEngine:
    """Ana karar motoru"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.ballistics = BallisticCalculator(config)
        self.stability_frames = config['decision']['detection_stability_frames']
        self.lock_timeout = config['decision']['target_lock_timeout']

        # Durum takibi
        self.current_tour = None
        self.target_status = TargetStatus.SEARCHING
        self.detection_counter = 0
        self.last_detection_frame = 0
        self.locked_target = None

    def set_tour_type(self, tour_type: TourType):
        """Tur tipini ayarla"""
        self.current_tour = tour_type
        logger.info(f"Tur tipi ayarlandı: {tour_type.name}")

    def update_target_tracking(self, target: Optional[TargetInfo]) -> TargetStatus:
        """
        Hedef takibini güncelle

        Args:
            target: Hedef bilgisi

        Returns:
            Güncel hedef durumu
        """
        if target is None:
            # Hedef kayboldu
            self.detection_counter = max(0, self.detection_counter - 1)

            if self.detection_counter == 0:
                self.target_status = TargetStatus.LOST
                logger.warning("Hedef kaybedildi")

            return self.target_status

        # Hedef tespit edildi
        self.detection_counter = min(self.stability_frames, self.detection_counter + 1)

        if self.detection_counter >= self.stability_frames:
            # Hedef kararlı - kilitle
            self.target_status = TargetStatus.LOCKED
            self.locked_target = target
            logger.info("Hedef kilitlendi")
        else:
            self.target_status = TargetStatus.DETECTED

        return self.target_status

    def should_fire(
        self,
        target: TargetInfo,
        gps_data: Dict[str, float],
        altitude: float,
        wind_speed: float = 0.0
    ) -> tuple[bool, Optional[Dict[str, Any]]]:
        """
        Ateş kararı ver

        Args:
            target: Hedef bilgisi
            gps_data: GPS koordinatları
            altitude: İrtifa
            wind_speed: Rüzgar hızı

        Returns:
            (ateş_edebilir_mi, balistik_çözüm)
        """
        # Hedef kilitli değilse ateş etme
        if self.target_status != TargetStatus.LOCKED:
            return False, None

        # Mesafe ve açı hesapla (eğer varsa)
        if target.distance is None or target.angle is None:
            logger.warning("Hedef mesafe/açı bilgisi eksik")
            return False, None

        # Balistik hesaplama
        solution = self.ballistics.calculate_firing_solution(
            target.distance,
            target.angle,
            wind_speed,
            altitude
        )

        # Ateş kararı
        can_fire = solution['can_fire']

        if can_fire:
            logger.info(f"ATEŞ HAZIR! Mesafe: {target.distance:.2f}m, Açı: {target.angle:.2f}°")
        else:
            logger.debug(f"Ateş şartları sağlanmadı: {solution}")

        return can_fire, solution

    def calculate_target_distance(
        self,
        target_pixel_area: float,
        altitude: float,
        camera_params: Dict[str, Any]
    ) -> float:
        """
        Hedef mesafesini piksel alanı ve irtifa ile hesapla

        Args:
            target_pixel_area: Hedef piksel alanı
            altitude: İrtifa (m)
            camera_params: Kamera parametreleri

        Returns:
            Hesaplanan mesafe (m)
        """
        # Basitleştirilmiş mesafe tahmini
        # Gerçek uygulamada kamera kalibrasyonu ve hedef boyutu gerekir

        # Örnek hesaplama (kamera FOV ve hedef boyutu varsayımları ile)
        focal_length = camera_params.get('focal_length', 1000)  # piksel cinsinden
        target_real_size = 0.5  # metre (hedefin gerçek boyutu)

        # Basit benzerlik oranı
        distance = (focal_length * target_real_size * altitude) / np.sqrt(target_pixel_area)

        return distance

    def process_decision(
        self,
        vision_result: Optional[Dict[str, Any]],
        sensor_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Tüm verileri işle ve karar ver

        Args:
            vision_result: Görüntü işleme sonucu
            sensor_data: Sensör verileri (GPS, IMU, altitude)

        Returns:
            Karar sonucu
        """
        decision = {
            'target_status': self.target_status.value,
            'can_fire': False,
            'fire_solution': None,
            'target_info': None
        }

        if vision_result is None:
            self.update_target_tracking(None)
            return decision

        # Hedef bilgisini oluştur
        target = TargetInfo(
            center=vision_result['center'],
            area=vision_result['area'],
            confidence=vision_result.get('confidence', 1.0)
        )

        # Mesafe hesapla
        altitude = sensor_data.get('altitude', 0.0)
        if altitude > 0:
            camera_params = {'focal_length': 1000}  # Örnek değer
            target.distance = self.calculate_target_distance(
                target.area,
                altitude,
                camera_params
            )

        # Hedef takibini güncelle
        status = self.update_target_tracking(target)
        decision['target_status'] = status.value

        # Ateş kararı
        if status == TargetStatus.LOCKED:
            gps_data = sensor_data.get('gps', {})
            wind_speed = self.ballistics.wind_speed

            can_fire, solution = self.should_fire(target, gps_data, altitude, wind_speed)
            decision['can_fire'] = can_fire
            decision['fire_solution'] = solution

        decision['target_info'] = target

        return decision
