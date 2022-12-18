#!/usr/bin/python3

import serial
import time

ser = serial.Serial(port="/dev/cu.usbserial-AB0M3BRO", baudrate=9600, timeout=1)
iCount = 0
while True:
    iCount += 1
    print(iCount)
    ser.write(bytes("M:x =     1 y =     2 z =     3, t =    10\n",'utf-8'))
    time.sleep(0.1)
    
