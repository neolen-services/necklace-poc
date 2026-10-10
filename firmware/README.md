# MMH Posture firmware

Firmware for the Seeed Studio XIAO nRF52840 Sense. It reads the onboard LSM6DS3TR-C, measures tilt from a calibrated upright position, vibrates when you slouch in training mode, and syncs history to the Flutter app over BLE.

The phone app is the rest of this repo. Protocol bytes match `lib/ble/protocol.dart`.

## Hardware

- Board: Seeed Studio XIAO nRF52840 Sense (IMU required).
- Vibration: a coin motor on **D0**, switched by an NPN transistor (or a motor module that accepts a 3.3 V GPIO). The red LED pulses with the same pattern, so a bare board still shows the buzz.
- Power: USB for development. Battery percent is reported when the board variant exposes `PIN_VBAT` (LiPo on the battery pads). `0` means "no reading".

There is no realtime clock. The app writes UTC time on each connect. History recorded after a reboot is kept only once the app has set the clock.

## Build and flash

Install PlatformIO, then from this folder:

```text
pip install platformio
pio run
pio run -t upload
pio device monitor
```

The board uses the Adafruit nRF52 core (Bluefruit), via Seeed's PlatformIO platform. `platformio.ini` selects `seeed-xiao-afruitnrf52-nrf52840-sense`. If that board id is not in your platform checkout, change it to `seeed-xiao-afruitnrf52-nrf52840`.

If upload cannot find the port, double-tap RESET to enter the UF2 bootloader and run `pio run -t upload` again.

Serial log is 115200 8N1. The device advertises as **MMH Posture**.

## Behavior

- Angle is the angle between the low-pass gravity vector and a stored upright reference. Wear orientation does not matter. Upper-back vs necklace is stored for the app only.
- Calibration averages about half a second of samples. The app sends it, or auto-calibration runs after the device is picked up and then held still (put on, sit upright). A long stillness (on a table) clears "worn" and arms auto-calibration for the next time you put it on.
- Slouch: angle above the threshold (default 15°) for the delay (default 5 s). Training mode pulses the motor (200 ms on / 600 ms off). Tracking mode logs the slouch and stays silent.
- Clearing the threshold by 2° ends the slouch and stores start time, duration, and peak angle.
- Each worn minute is stored as upright seconds and slouch seconds.

## BLE

Advertised service `8f3a0001-7c2b-4d6e-9a10-b1c2d3e4f5a6`.

Also exposes the standard Battery Service and Device Information (firmware `2.4.1`, model `Necklace`).

All multi-byte integers are little-endian.

### Live `8f3a0002-7c2b-4d6e-9a10-b1c2d3e4f5a6` (notify, 4 bytes, 5 Hz)

| Offset | Type | Meaning |
| --- | --- | --- |
| 0 | int16 | Angle in tenths of a degree from upright. 0 until calibrated. |
| 2 | uint8 | Flags |
| 3 | uint8 | Battery percent, or 0 if unknown |

Flags: bit0 upright, bit1 slouching, bit2 calibrating, bit3 worn, bit4 buzzing, bit5 calibrated, bit6 pending (over the angle, still inside the delay), bit7 sensor fault.

### Config `8f3a0003-7c2b-4d6e-9a10-b1c2d3e4f5a6` (read/write, 8 bytes)

| Offset | Type | Meaning |
| --- | --- | --- |
| 0 | uint8 | Mode: 0 training, 1 tracking only |
| 1 | uint8 | Threshold degrees, clamped 5–45 (default 15) |
| 2 | uint8 | Delay seconds, clamped 0–30 (default 5) |
| 3 | uint8 | Vibration strength 0–100 (default 70) |
| 4 | uint8 | Wear: 0 upper back, 1 necklace |
| 5 | uint8 | Auto-calibration: 0 off, 1 on |
| 6 | uint16 | Reserved, write 0 |

### Command `8f3a0004-7c2b-4d6e-9a10-b1c2d3e4f5a6` (write)

| First byte | Payload | Action |
| --- | --- | --- |
| 1 | none | Calibrate now |
| 2 | none | Test vibration for 800 ms, even in tracking mode |
| 3 | uint32 UTC epoch | Set the clock |
| 4 | none | Clear stored history |
| 5 | none | Stream history notifications |
| 6 | uint32 seq | Delete records with `seq` less than or equal to this |

### History `8f3a0005-7c2b-4d6e-9a10-b1c2d3e4f5a6` (notify, 14 bytes)

| Offset | Type | Meaning |
| --- | --- | --- |
| 0 | uint32 | Sequence, starting at 1 |
| 4 | uint8 | Type: 1 minute, 2 slouch, 3 sync end |
| 5 | uint32 | Epoch (UTC). Minute start, or slouch start. |
| 9 | uint16 | Minute: upright seconds. Slouch: duration seconds. End: 1 = batch finished. |
| 11 | uint16 | Minute: slouch seconds. Otherwise 0. |
| 13 | uint8 | Peak angle in degrees |

Sync: app sets the time, writes command 5, stores each record, then writes command 6 with the highest seq it saved. The device only notifies seqs above the last ack. A type 3 record ends the batch.

History is a 480-record ring in RAM, mirrored to the onboard flash filesystem at most every 5 minutes and on slouch-end, ack, and disconnect.
