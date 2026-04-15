import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static Future<void> downloadAndShare(String url, String fileName) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      
      // 1. Generate a stable, unique path based on the URL (to identify if we already have it)
      final ext = p.extension(url.split('?').first);
      final urlHash = url.substring(url.length - 15).replaceAll(RegExp(r'[^\w]'), ''); // simple hash from url tail
      final safeName = fileName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final savePath = '${tempDir.path}/${safeName}_$urlHash$ext';

      final file = File(savePath);

      // 2. Optimization: If file exists locally, use it! (Fixes "Duplicate Fetch" Flaw)
      if (await file.exists()) {
        await Share.shareXFiles([XFile(savePath)], text: 'Opening: $fileName');
        return;
      }

      // 3. Download if not found
      await dio.download(url, savePath);

      // 4. Share/Open native sheet
      await Share.shareXFiles([XFile(savePath)], text: 'Download: $fileName');
      
    } catch (e) {
      rethrow;
    }
  }
}
