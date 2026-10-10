import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureBlePermissions() async {
  final scan = await Permission.bluetoothScan.request();
  final connect = await Permission.bluetoothConnect.request();
  await Permission.notification.request();
  if (scan.isGranted && connect.isGranted) return true;

  // Android 11 and earlier scan with location instead of the Bluetooth permissions.
  final location = await Permission.locationWhenInUse.request();
  return location.isGranted && (scan.isGranted || scan.isLimited || !scan.isDenied);
}
