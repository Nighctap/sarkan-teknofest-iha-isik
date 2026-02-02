"""
Hedef Tespit Modülü (YOLO)
YOLOv8 ile hedef ve iniş bölgesi tespiti
"""

import cv2
import numpy as np
from typing import List, Dict, Any, Optional
from loguru import logger
from ultralytics import YOLO


class TargetDetector:
    """YOLOv8 tabanlı hedef tespit sistemi"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.model_path = config['detection']['model_path']
        self.confidence_threshold = config['detection']['confidence_threshold']
        self.iou_threshold = config['detection']['iou_threshold']
        self.classes = config['detection']['classes']
        self.model = None

    def initialize(self) -> bool:
        """YOLO modelini yükle"""
        try:
            self.model = YOLO(self.model_path)
            logger.info(f"YOLO modeli yüklendi: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"YOLO model yükleme hatası: {e}")
            return False

    def detect(self, frame: np.ndarray) -> List[Dict[str, Any]]:
        """
        Frame üzerinde hedef tespiti yap

        Args:
            frame: BGR formatında giriş görüntüsü

        Returns:
            Tespit edilen hedef listesi
        """
        if self.model is None:
            logger.error("Model yüklenmemiş")
            return []

        try:
            # YOLO inference
            results = self.model(
                frame,
                conf=self.confidence_threshold,
                iou=self.iou_threshold,
                verbose=False
            )

            detections = []

            for result in results:
                boxes = result.boxes

                for box in boxes:
                    # Koordinatlar
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    confidence = float(box.conf[0])
                    class_id = int(box.cls[0])
                    class_name = result.names[class_id]

                    # Merkez nokta
                    center_x = (x1 + x2) // 2
                    center_y = (y1 + y2) // 2

                    detection = {
                        'bbox': (x1, y1, x2, y2),
                        'center': (center_x, center_y),
                        'confidence': confidence,
                        'class_id': class_id,
                        'class_name': class_name,
                        'area': (x2 - x1) * (y2 - y1)
                    }

                    detections.append(detection)
                    logger.debug(f"Tespit: {class_name} ({confidence:.2f}) @ ({center_x}, {center_y})")

            return detections

        except Exception as e:
            logger.error(f"Tespit hatası: {e}")
            return []

    def draw_detections(self, frame: np.ndarray, detections: List[Dict[str, Any]]) -> np.ndarray:
        """
        Tespitleri görüntü üzerine çiz

        Args:
            frame: BGR formatında giriş görüntüsü
            detections: Tespit listesi

        Returns:
            İşaretlenmiş görüntü
        """
        frame_copy = frame.copy()

        for det in detections:
            x1, y1, x2, y2 = det['bbox']
            confidence = det['confidence']
            class_name = det['class_name']
            center = det['center']

            # Bounding box
            color = (0, 255, 0) if class_name == 'target' else (255, 0, 0)
            cv2.rectangle(frame_copy, (x1, y1), (x2, y2), color, 2)

            # Label
            label = f"{class_name}: {confidence:.2f}"
            cv2.putText(frame_copy, label, (x1, y1 - 10),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

            # Merkez
            cv2.circle(frame_copy, center, 5, (0, 0, 255), -1)

        return frame_copy

    def get_best_target(self, detections: List[Dict[str, Any]], target_class: str = 'target') -> Optional[Dict[str, Any]]:
        """
        En yüksek güvenilirliğe sahip hedefi seç

        Args:
            detections: Tespit listesi
            target_class: Hedef sınıf adı

        Returns:
            En iyi hedef veya None
        """
        targets = [d for d in detections if d['class_name'] == target_class]

        if not targets:
            return None

        # En yüksek confidence'a sahip olanı seç
        best_target = max(targets, key=lambda x: x['confidence'])
        return best_target
