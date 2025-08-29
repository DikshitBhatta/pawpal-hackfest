import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  // Target size in bytes (1MB = 1024 * 1024 bytes)
  // We'll target 800KB to leave some buffer for Firestore document overhead
  static const int targetSizeBytes = 800 * 1024; // 800KB
  
  /// Compresses an image to be under the target size for Firestore storage
  /// Returns base64 encoded string that can be stored in Firestore
  static Future<String?> compressImageForFirestore(File imageFile) async {
    try {
      // First, get the original file size
      int originalSize = await imageFile.length();
      print('Original image size: ${(originalSize / 1024).round()}KB');
      
      if (originalSize <= targetSizeBytes) {
        // If already under target, just convert to base64
        Uint8List imageBytes = await imageFile.readAsBytes();
        String base64String = base64Encode(imageBytes);
        print('Image already under target size, returning as base64');
        return base64String;
      }
      
      // Calculate initial quality based on size ratio
      double sizeRatio = targetSizeBytes / originalSize;
      int initialQuality = (sizeRatio * 100).clamp(10, 85).round();
      
      print('Compressing image with initial quality: $initialQuality%');
      
      // Compress the image
      Uint8List? compressedBytes = await _compressImage(
        imageFile, 
        quality: initialQuality
      );
      
      if (compressedBytes == null) {
        print('Failed to compress image');
        return null;
      }
      
      print('Compressed image size: ${(compressedBytes.length / 1024).round()}KB');
      
      // If still too large, try with lower quality
      if (compressedBytes.length > targetSizeBytes && initialQuality > 10) {
        print('Still too large, compressing with lower quality...');
        compressedBytes = await _compressWithBinarySearch(imageFile);
      }
      
      if (compressedBytes == null || compressedBytes.length > targetSizeBytes) {
        print('Could not compress image to target size');
        return null;
      }
      
      // Convert to base64
      String base64String = base64Encode(compressedBytes);
      print('Final compressed size: ${(compressedBytes.length / 1024).round()}KB');
      
      return base64String;
      
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
  
  /// Compresses image with specified quality
  static Future<Uint8List?> _compressImage(File file, {required int quality}) async {
    try {
      // Compress the image directly to bytes
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
        format: CompressFormat.jpeg, // Convert to JPEG for better compression
        keepExif: false, // Remove EXIF data to save space
      );
      
      return compressedBytes;
      
    } catch (e) {
      print('Error in _compressImage: $e');
      return null;
    }
  }
  
  /// Uses binary search to find the optimal quality for target size
  static Future<Uint8List?> _compressWithBinarySearch(File file) async {
    int minQuality = 10;
    int maxQuality = 85;
    Uint8List? bestResult;
    
    while (minQuality <= maxQuality) {
      int midQuality = (minQuality + maxQuality) ~/ 2;
      
      Uint8List? compressed = await _compressImage(file, quality: midQuality);
      
      if (compressed == null) {
        maxQuality = midQuality - 1;
        continue;
      }
      
      if (compressed.length <= targetSizeBytes) {
        // This quality works, try higher quality
        bestResult = compressed;
        minQuality = midQuality + 1;
      } else {
        // Too large, try lower quality
        maxQuality = midQuality - 1;
      }
    }
    
    return bestResult;
  }
  
  /// Converts base64 string back to image file (for display purposes)
  static Future<File?> base64ToImageFile(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error converting base64 to file: $e');
      return null;
    }
  }
  
  /// Gets image info (for debugging)
  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final sizeKB = (bytes.length / 1024).round();
      
      return {
        'sizeBytes': bytes.length,
        'sizeKB': sizeKB,
        'sizeMB': (sizeKB / 1024).toStringAsFixed(2),
        'path': imageFile.path,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
