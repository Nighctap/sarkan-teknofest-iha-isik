"""
Renk Filtresi Modülü (1. Tur İşleme)
Kırmızı, Yeşil, Mavi hedef algılama için HSV tabanlı renk filtreleme
"""

import cv2
import numpy as np
from typing import List, Tuple, Optional, Dict, Any
from loguru import logger


class ColorFilter:
    """HSV renk filtresi ile hedef algılama"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.color_ranges = config['image_processing']['color_filters']
        self.kernel_size = config['image_processing']['morphology']['kernel_size']
        self.iterations = config['image_processing']['morphology']['iterations']
        self.min_area = config['image_processing']['contour']['min_area']
        self.max_area = config['image_processing']['contour']['max_area']

    def apply_color_filter(self, frame: np.ndarray, color: str) -> np.ndarray:
        """
        Belirtilen renge göre HSV filtresi uygula

        Args:
            frame: BGR formatında giriş görüntüsü
            color: 'red', 'green', 'blue'

        Returns:
            Binary mask
        """
        if color not in self.color_ranges:
            logger.error(f"Geçersiz renk: {color}")
            return np.zeros(frame.shape[:2], dtype=np.uint8)

        # BGR'den HSV'ye dönüştür
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

        # Renk aralığını al
        color_range = self.color_ranges[color]
        lower = np.array(color_range['lower_hsv'])
        upper = np.array(color_range['upper_hsv'])

        # Kırmızı renk için özel durum (HSV'de 0 ve 180'de)
        if color == 'red':
            lower1 = np.array([0, 120, 70])
            upper1 = np.array([10, 255, 255])
            lower2 = np.array([170, 120, 70])
            upper2 = np.array([180, 255, 255])

            mask1 = cv2.inRange(hsv, lower1, upper1)
            mask2 = cv2.inRange(hsv, lower2, upper2)
            mask = cv2.bitwise_or(mask1, mask2)
        else:
            mask = cv2.inRange(hsv, lower, upper)

        return mask

    def apply_morphology(self, mask: np.ndarray) -> np.ndarray:
        """
        Morfolojik işlemler uygula (gürültü azaltma)

        Args:
            mask: Binary mask

        Returns:
            İşlenmiş mask
        """
        kernel = np.ones((self.kernel_size, self.kernel_size), np.uint8)

        # Opening (erosion + dilation) - küçük gürültüleri temizle
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=self.iterations)

        # Closing (dilation + erosion) - boşlukları doldur
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=self.iterations)

        return mask

    def find_contours(self, mask: np.ndarray) -> List[np.ndarray]:
        """
        Konturları bul ve filtrele

        Args:
            mask: Binary mask

        Returns:
            Filtrelenmiş kontur listesi
        """
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Alan filtresi uygula
        filtered_contours = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if self.min_area <= area <= self.max_area:
                filtered_contours.append(contour)

        return filtered_contours

    def get_target_center(self, contour: np.ndarray) -> Tuple[int, int]:
        """
        Konturun merkez noktasını hesapla

        Args:
            contour: Kontur

        Returns:
            (x, y) merkez koordinatları
        """
        M = cv2.moments(contour)
        if M["m00"] != 0:
            cx = int(M["m10"] / M["m00"])
            cy = int(M["m01"] / M["m00"])
            return (cx, cy)
        return (0, 0)

    def process_frame(self, frame: np.ndarray, target_color: str) -> Optional[Dict[str, Any]]:
        """
        Frame üzerinde renk filtresi işlemi yap ve hedef bul

        Args:
            frame: BGR formatında giriş görüntüsü
            target_color: Hedef renk ('red', 'green', 'blue')

        Returns:
            Hedef bilgileri (merkez, alan, kontur) veya None
        """
        # Renk filtresi uygula
        mask = self.apply_color_filter(frame, target_color)

        # Morfolojik işlemler
        mask = self.apply_morphology(mask)

        # Konturları bul
        contours = self.find_contours(mask)

        if not contours:
            return None

        # En büyük konturu seç (en büyük hedef)
        largest_contour = max(contours, key=cv2.contourArea)
        area = cv2.contourArea(largest_contour)
        center = self.get_target_center(largest_contour)

        # Sınırlayıcı kutu
        x, y, w, h = cv2.boundingRect(largest_contour)

        result = {
            'center': center,
            'area': area,
            'contour': largest_contour,
            'bounding_box': (x, y, w, h),
            'mask': mask,
            'color': target_color
        }

        logger.debug(f"{target_color.upper()} hedef bulundu: Merkez={center}, Alan={area:.2f}")
        return result

    def draw_detection(self, frame: np.ndarray, detection: Dict[str, Any]) -> np.ndarray:
        """
        Tespit edilen hedefi görüntü üzerine çiz

        Args:
            frame: BGR formatında giriş görüntüsü
            detection: Tespit sonucu

        Returns:
            İşaretlenmiş görüntü
        """
        frame_copy = frame.copy()

        # Kontur çiz
        cv2.drawContours(frame_copy, [detection['contour']], -1, (0, 255, 0), 3)

        # Merkez noktası
        center = detection['center']
        cv2.circle(frame_copy, center, 5, (0, 0, 255), -1)

        # Sınırlayıcı kutu
        x, y, w, h = detection['bounding_box']
        cv2.rectangle(frame_copy, (x, y), (x + w, y + h), (255, 0, 0), 2)

        # Metin bilgisi
        text = f"{detection['color'].upper()} - Area: {detection['area']:.0f}"
        cv2.putText(frame_copy, text, (x, y - 10),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)

        return frame_copy
