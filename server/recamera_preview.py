import cv2
import sys

# แก้เป็น IP และ URL ของ reCamera
CAMERA_URL = "http://192.168.42.1/api/v1/camera/stream"

print("กำลังเปิดกล้อง:", CAMERA_URL)

cap = cv2.VideoCapture(CAMERA_URL)

if not cap.isOpened():
    print("เปิดกล้องไม่ได้")
    print("ตรวจสอบ IP หรือ URL ของ reCamera")
    sys.exit(1)

while True:
    ok, frame = cap.read()

    if not ok:
        print("รับภาพจากกล้องไม่ได้")
        break

    cv2.imshow("reCamera Preview - กด Q เพื่อปิด", frame)

    key = cv2.waitKey(1) & 0xFF

    if key in (ord("q"), ord("Q"), 27):
        break

cap.release()
cv2.destroyAllWindows()