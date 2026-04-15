import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request gallery/storage permission for media uploading
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) return true;
    
    // For Android 13+ (SDK 33+), we check photos instead of storage
    if (await Permission.photos.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    return false;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    return await Permission.camera.request().isGranted;
  }

  /// Request location for geofenced attendance
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}
