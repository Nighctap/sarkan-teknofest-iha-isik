"""
Sensör Yönetim Modülü
Kamera ve Pixhawk/Hava Hızı sensörlerini yönetir
"""

import cv2
import numpy as np
from typing import Optional, Dict, Any
from loguru import logger
from pymavlink import mavutil


class CameraManager:
    """Kamera yönetimi ve görüntü yakalama"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.camera = None
        self.resolution = (
            config['camera']['resolution']['width'],
            config['camera']['resolution']['height']
        )
        self.fps = config['camera']['fps']

    def initialize(self) -> bool:
        """Kamerayı başlat"""
        try:
            source = self.config['camera']['source']
            self.camera = cv2.VideoCapture(source)

            if not self.camera.isOpened():
                logger.error("Kamera açılamadı")
                return False

            self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, self.resolution[0])
            self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, self.resolution[1])
            self.camera.set(cv2.CAP_PROP_FPS, self.fps)

            logger.info(f"Kamera başlatıldı: {self.resolution[0]}x{self.resolution[1]}@{self.fps}fps")
            return True

        except Exception as e:
            logger.error(f"Kamera başlatma hatası: {e}")
            return False

    def read_frame(self) -> Optional[np.ndarray]:
        """Kameradan frame oku"""
        if self.camera is None or not self.camera.isOpened():
            return None

        ret, frame = self.camera.read()
        if not ret:
            logger.warning("Frame okunamadı")
            return None

        return frame

    def release(self):
        """Kamera kaynaklarını serbest bırak"""
        if self.camera is not None:
            self.camera.release()
            logger.info("Kamera kapatıldı")


class PixhawkManager:
    """Pixhawk/Cube uçuş kontrol kartı ile iletişim"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = None
        self.gps_data = {}
        self.attitude_data = {}
        self.altitude = 0.0

    def initialize(self) -> bool:
        """Pixhawk bağlantısını başlat"""
        try:
            connection_string = self.config['sensors']['pixhawk']['connection_string']
            self.connection = mavutil.mavlink_connection(connection_string)

            # İlk heartbeat'i bekle
            self.connection.wait_heartbeat()
            logger.info(f"Pixhawk'a bağlanıldı (System {self.connection.target_system}, Component {self.connection.target_component})")

            return True

        except Exception as e:
            logger.error(f"Pixhawk bağlantı hatası: {e}")
            return False

    def update_telemetry(self):
        """Telemetri verilerini güncelle"""
        if self.connection is None:
            return

        try:
            # GPS verisi
            msg = self.connection.recv_match(type='GLOBAL_POSITION_INT', blocking=False)
            if msg:
                self.gps_data = {
                    'lat': msg.lat / 1e7,
                    'lon': msg.lon / 1e7,
                    'alt': msg.alt / 1000.0,
                    'relative_alt': msg.relative_alt / 1000.0
                }

            # Attitude verisi
            msg = self.connection.recv_match(type='ATTITUDE', blocking=False)
            if msg:
                self.attitude_data = {
                    'roll': msg.roll,
                    'pitch': msg.pitch,
                    'yaw': msg.yaw
                }

        except Exception as e:
            logger.error(f"Telemetri güncelleme hatası: {e}")

    def get_gps_coordinates(self) -> Optional[Dict[str, float]]:
        """GPS koordinatlarını al"""
        return self.gps_data if self.gps_data else None

    def get_altitude(self) -> float:
        """Göreceli yüksekliği al"""
        return self.gps_data.get('relative_alt', 0.0)

    def get_attitude(self) -> Optional[Dict[str, float]]:
        """İHA açısal konumunu al"""
        return self.attitude_data if self.attitude_data else None

    def send_servo_command(self, channel: int, pwm: int):
        """Servo komandu gönder (ateşleme mekanizması için)"""
        try:
            self.connection.mav.command_long_send(
                self.connection.target_system,
                self.connection.target_component,
                mavutil.mavlink.MAV_CMD_DO_SET_SERVO,
                0,
                channel,  # Servo kanalı
                pwm,      # PWM değeri
                0, 0, 0, 0, 0
            )
            logger.info(f"Servo komutu gönderildi: Kanal {channel}, PWM {pwm}")
        except Exception as e:
            logger.error(f"Servo komutu hatası: {e}")

    def close(self):
        """Bağlantıyı kapat"""
        if self.connection:
            self.connection.close()
            logger.info("Pixhawk bağlantısı kapatıldı")
