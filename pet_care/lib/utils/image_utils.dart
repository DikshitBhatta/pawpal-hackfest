import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ImageUtils {
  // Check if the image string is base64 encoded
  static bool isBase64(String str) {
    return str.startsWith('data:image/') && str.contains('base64,');
  }

  // Extract base64 data from data URL
  static String extractBase64(String dataUrl) {
    return dataUrl.split('base64,')[1];
  }

  // Convert base64 string to Uint8List
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

    // Create ImageProvider based on image source
  static ImageProvider getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      // Return default petPic as fallback for user profiles too
      return AssetImage('assets/images/petPic.png');
    }

    // Skip known problematic URLs
    if (imagePath.contains('via.placeholder.com') || 
        imagePath.contains('placeholder') && imagePath.contains('http')) {
      return AssetImage('assets/images/petPic.png');
    }

    if (isBase64(imagePath)) {
      // Handle base64 image
      try {
        String base64Data = extractBase64(imagePath);
        Uint8List bytes = base64ToBytes(base64Data);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding base64 image: $e');
        return AssetImage('assets/images/petPic.png');
      }
    } else if (imagePath.startsWith('assets/')) {
      // Handle asset image
      return AssetImage(imagePath);
    } else if (imagePath.startsWith('http')) {
      // Handle network image - Flutter will handle errors internally
      return NetworkImage(imagePath);
    } else {
      // Default fallback
      return AssetImage('assets/images/petPic.png');
    }
  }

  // Create ImageProvider specifically for pet images
  static ImageProvider getPetImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      // Return default pet placeholder
      return AssetImage('assets/images/petPic.png');
    }

    // Skip known problematic URLs
    if (imagePath.contains('via.placeholder.com') || 
        imagePath.contains('placeholder') && imagePath.contains('http')) {
      return AssetImage('assets/images/petPic.png');
    }

    if (isBase64(imagePath)) {
      // Handle base64 image
      try {
        String base64Data = extractBase64(imagePath);
        Uint8List bytes = base64ToBytes(base64Data);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error loading base64 pet image: $e');
        return AssetImage('assets/images/petPic.png');
      }
    } else if (imagePath.startsWith('assets/')) {
      // Handle asset image
      return AssetImage(imagePath);
    } else if (imagePath.startsWith('http')) {
      // Handle network image - Flutter will handle errors internally
      return NetworkImage(imagePath);
    } else {
      // Default fallback for pets
      return AssetImage('assets/images/petPic.png');
    }
  }

  // Create a CircleAvatar with proper image handling
  static CircleAvatar buildProfileAvatar({
    required String? imagePath,
    double radius = 30,
    Color backgroundColor = Colors.white70,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: getImageProvider(imagePath),
      backgroundColor: backgroundColor,
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading profile image: $exception');
      },
    );
  }

  // Create a Container with proper image handling
  static Container buildProfileContainer({
    required String? imagePath,
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        image: DecorationImage(
          image: getImageProvider(imagePath),
          fit: fit,
          onError: (exception, stackTrace) {
            print('Error loading profile image: $exception');
          },
        ),
      ),
    );
  }

  // Create a CircleAvatar specifically for pet images
  static CircleAvatar buildPetAvatar({
    required String? imagePath,
    double radius = 30,
    Color backgroundColor = Colors.white70,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: getPetImageProvider(imagePath),
      backgroundColor: backgroundColor,
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading pet image: $exception');
      },
    );
  }

  // Create a Container specifically for pet images
  static Container buildPetContainer({
    required String? imagePath,
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        image: DecorationImage(
          image: getPetImageProvider(imagePath),
          fit: fit,
          onError: (exception, stackTrace) {
            print('Error loading pet image: $exception');
          },
        ),
      ),
    );
  }

  // Create a safe Image widget with fallback for network images
  static Widget buildSafeNetworkImage({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isPetImage = false,
  }) {
    // Use petPic.png as default for both user and pet images
    String fallbackAsset = 'assets/images/petPic.png';
    
    if (imagePath == null || 
        imagePath.isEmpty || 
        imagePath.contains('via.placeholder.com') ||
        (!imagePath.startsWith('http') && !imagePath.startsWith('assets/') && !isBase64(imagePath))) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (isBase64(imagePath)) {
      try {
        String base64Data = extractBase64(imagePath);
        Uint8List bytes = base64ToBytes(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              fallbackAsset,
              width: width,
              height: height,
              fit: fit,
            );
          },
        );
      } catch (e) {
        return Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            child: Center(
              child: Lottie.asset(
                'assets/Animations/AnimalcareLoading.json',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Network image failed: $error');
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
