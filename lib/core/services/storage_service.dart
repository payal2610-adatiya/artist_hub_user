import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> createFolder(String folderName) async {
    final appDir = await getAppDirectory();
    final folderPath = '$appDir/$folderName';
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return folderPath;
  }

  static Future<String> getMediaFolder() async {
    return await createFolder('artist_hub_media');
  }

  static Future<String> saveFileLocally(File file, String fileName) async {
    final mediaFolder = await getMediaFolder();
    final newPath = '$mediaFolder/$fileName';
    await file.copy(newPath);
    return newPath;
  }

  static Future<bool> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<File?> getLocalFile(String fileName) async {
    try {
      final mediaFolder = await getMediaFolder();
      final filePath = '$mediaFolder/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final mediaFolder = await getMediaFolder();
      final directory = Directory(mediaFolder);

      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<double> getCacheSize() async {
    try {
      final mediaFolder = await getMediaFolder();
      final directory = Directory(mediaFolder);

      if (!await directory.exists()) {
        return 0.0;
      }

      double totalSize = 0;
      final files = directory.listSync(recursive: true);

      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize / (1024 * 1024); // Return size in MB
    } catch (e) {
      return 0.0;
    }
  }
}