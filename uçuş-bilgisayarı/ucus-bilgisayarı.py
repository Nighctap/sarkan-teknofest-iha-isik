import collections
import collections.abc

# Dronekit Python 3.10+ hatasını düzeltmek için yama
if not hasattr(collections, 'MutableMapping'):
    collections.MutableMapping = collections.abc.MutableMapping


"""
Simple script for take off and control with arrow keys
"""
import time
from dronekit import connect, VehicleMode, LocationGlobalRelative

#-- Connect to the vehicle
print('Connecting...')
vehicle = connect('udp:127.0.0.1:14551', wait_ready=False)

#-- Define the function for takeoff
def arm_and_takeoff(tgt_altitude):
    print("Uçak hazırlanıyor...")

    while not vehicle.is_armable:
        print("Uçağın hazır olması bekleniyor (GPS vb.)...")
        time.sleep(1)

    # Uçaklarda kalkış için genellikle TAKEOFF modu kullanılır
    vehicle.mode = VehicleMode("TAKEOFF")
    vehicle.armed = True

    while not vehicle.armed:
        print("Arm bekleniyor...")
        time.sleep(1)

    print("Kalkış başlatıldı! (Pistte hızlanıyor...)")

    # İrtifa kontrolü
    while True:
        altitude = vehicle.location.global_relative_frame.alt
        print(f"Şu anki İrtifa: {altitude:.1f}m")
        if altitude >= tgt_altitude - 1:
            print("Hedef irtifaya ulaşıldı.")
            break
        time.sleep(1)

    # Kalktıktan sonra komut göndermek için GUIDED moda geçmelisin
    vehicle.mode = VehicleMode("GUIDED")


#MAIN PROGRAM
arm_and_takeoff(10)

#set the default speed
vehicle.airspeed = 15


time.sleep(3)

#Coming back
print("Coming back")
vehicle.mode = VehicleMode("RTL")

time.sleep(2)

#Close connection
vehicle.close()
