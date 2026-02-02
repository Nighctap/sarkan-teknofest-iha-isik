"""
Harita Yönetimi Modülü
GPS koordinatları ve hedef lokasyonlarını harita üzerinde gösterir
"""

import folium
from typing import List, Tuple, Dict, Any
from loguru import logger
from datetime import datetime
import json


class MapManager:
    """Harita yönetimi ve görselleştirme"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.coordinate_system = config['localization']['coordinate_system']
        self.save_trajectory = config['localization']['save_trajectory']

        self.trajectory = []
        self.target_locations = []
        self.map = None

    def initialize_map(self, center_coords: Tuple[float, float], zoom: int = 15):
        """
        Haritayı başlat

        Args:
            center_coords: (lat, lon) merkez koordinatları
            zoom: Zoom seviyesi
        """
        self.map = folium.Map(
            location=center_coords,
            zoom_start=zoom,
            tiles='OpenStreetMap'
        )
        logger.info(f"Harita başlatıldı: {center_coords}")

    def add_trajectory_point(self, coords: Tuple[float, float], altitude: float):
        """
        Trajectory noktası ekle

        Args:
            coords: (lat, lon) koordinatları
            altitude: İrtifa
        """
        point = {
            'coords': coords,
            'altitude': altitude,
            'timestamp': datetime.now().isoformat()
        }
        self.trajectory.append(point)

    def add_target_location(
        self,
        coords: Tuple[float, float],
        target_type: str,
        confidence: float
    ):
        """
        Hedef lokasyonu ekle

        Args:
            coords: (lat, lon) koordinatları
            target_type: Hedef tipi
            confidence: Güvenilirlik skoru
        """
        target = {
            'coords': coords,
            'type': target_type,
            'confidence': confidence,
            'timestamp': datetime.now().isoformat()
        }
        self.target_locations.append(target)
        logger.info(f"Hedef lokasyonu eklendi: {target_type} @ {coords}")

    def update_map(self):
        """Haritayı güncelle"""
        if self.map is None:
            logger.warning("Harita başlatılmamış")
            return

        # Trajectory çiz
        if len(self.trajectory) > 1:
            coords_list = [point['coords'] for point in self.trajectory]
            folium.PolyLine(
                coords_list,
                color='blue',
                weight=2,
                opacity=0.7,
                popup='İHA Yolu'
            ).add_to(self.map)

        # İHA pozisyonunu göster (son nokta)
        if self.trajectory:
            last_point = self.trajectory[-1]
            folium.Marker(
                last_point['coords'],
                popup=f"İHA - Alt: {last_point['altitude']:.1f}m",
                icon=folium.Icon(color='blue', icon='plane')
            ).add_to(self.map)

        # Hedef lokasyonlarını göster
        for target in self.target_locations:
            color = 'red' if target['type'] == 'target' else 'green'
            folium.Marker(
                target['coords'],
                popup=f"{target['type']} ({target['confidence']:.2f})",
                icon=folium.Icon(color=color, icon='crosshairs')
            ).add_to(self.map)

    def save_map(self, filepath: str):
        """
        Haritayı HTML dosyası olarak kaydet

        Args:
            filepath: Kayıt yolu
        """
        if self.map is None:
            logger.warning("Harita başlatılmamış")
            return

        try:
            self.map.save(filepath)
            logger.info(f"Harita kaydedildi: {filepath}")
        except Exception as e:
            logger.error(f"Harita kaydetme hatası: {e}")

    def save_trajectory_json(self, filepath: str):
        """
        Trajectory verilerini JSON olarak kaydet

        Args:
            filepath: Kayıt yolu
        """
        if not self.save_trajectory:
            return

        data = {
            'trajectory': self.trajectory,
            'targets': self.target_locations,
            'coordinate_system': self.coordinate_system
        }

        try:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            logger.info(f"Trajectory verisi kaydedildi: {filepath}")
        except Exception as e:
            logger.error(f"Trajectory kaydetme hatası: {e}")

    def get_statistics(self) -> Dict[str, Any]:
        """
        İstatistik bilgileri al

        Returns:
            İstatistik sözlüğü
        """
        total_distance = 0.0
        if len(self.trajectory) > 1:
            from geopy.distance import geodesic
            for i in range(1, len(self.trajectory)):
                dist = geodesic(
                    self.trajectory[i-1]['coords'],
                    self.trajectory[i]['coords']
                ).meters
                total_distance += dist

        stats = {
            'total_waypoints': len(self.trajectory),
            'total_distance_m': total_distance,
            'targets_detected': len(self.target_locations),
            'start_time': self.trajectory[0]['timestamp'] if self.trajectory else None,
            'end_time': self.trajectory[-1]['timestamp'] if self.trajectory else None
        }

        return stats
