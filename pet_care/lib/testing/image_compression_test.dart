import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pet_care/services/image_compression_service.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/widgets/firestore_image_widget.dart';

class ImageCompressionTestScreen extends StatefulWidget {
  @override
  _ImageCompressionTestScreenState createState() => _ImageCompressionTestScreenState();
}

class _ImageCompressionTestScreenState extends State<ImageCompressionTestScreen> {
  File? originalImage;
  String? uploadedImageId;
  bool isUploading = false;
  Map<String, dynamic>? originalImageInfo;
  Map<String, dynamic>? compressedImageInfo;

  Future<void> _pickAndTestImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;
      
      setState(() {
        originalImage = File(image.path);
        uploadedImageId = null;
        originalImageInfo = null;
        compressedImageInfo = null;
      });
      
      // Get original image info
      final info = await ImageCompressionService.getImageInfo(originalImage!);
      setState(() {
        originalImageInfo = info;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  Future<void> _compressAndUpload() async {
    if (originalImage == null) return;
    
    setState(() {
      isUploading = true;
    });
    
    try {
      // Test compression
      final compressedBase64 = await ImageCompressionService.compressImageForFirestore(originalImage!);
      
      if (compressedBase64 != null) {
        // Calculate compressed size
        final compressedBytes = compressedBase64.length;
        final compressedKB = (compressedBytes / 1024).round();
        
        setState(() {
          compressedImageInfo = {
            'sizeBytes': compressedBytes,
            'sizeKB': compressedKB,
            'sizeMB': (compressedKB / 1024).toStringAsFixed(2),
          };
        });
        
        // Upload to Firestore
        final imageId = await DataBase.uploadImage(
          'test@example.com', 
          'TestImages', 
          originalImage!
        );
        
        setState(() {
          uploadedImageId = imageId;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Image compressed and uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Compression failed');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Compression Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pick Image Button
            ElevatedButton.icon(
              onPressed: _pickAndTestImage,
              icon: Icon(Icons.photo_library),
              label: Text('Pick Image from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Original Image Section
            if (originalImage != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📸 Original Image',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            originalImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (originalImageInfo != null) ...[
                        SizedBox(height: 10),
                        Text('Size: ${originalImageInfo!['sizeKB']} KB (${originalImageInfo!['sizeMB']} MB)'),
                        Text('Bytes: ${originalImageInfo!['sizeBytes']}'),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Compress and Upload Button
              ElevatedButton.icon(
                onPressed: isUploading ? null : _compressAndUpload,
                icon: isUploading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.compress),
                label: Text(isUploading ? 'Compressing...' : 'Compress & Upload to Firestore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Compression Results
            if (compressedImageInfo != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🗜️ Compression Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                      SizedBox(height: 10),
                      Text('Compressed Size: ${compressedImageInfo!['sizeKB']} KB (${compressedImageInfo!['sizeMB']} MB)'),
                      Text('Compressed Bytes: ${compressedImageInfo!['sizeBytes']}'),
                      if (originalImageInfo != null) ...[
                        SizedBox(height: 5),
                        Text(
                          'Reduction: ${((originalImageInfo!['sizeBytes'] - compressedImageInfo!['sizeBytes']) / originalImageInfo!['sizeBytes'] * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                      ],
                      Text(
                        compressedImageInfo!['sizeBytes'] < 1024 * 1024 
                          ? '✅ Under 1MB - Safe for Firestore!'
                          : '❌ Still over 1MB - Need more compression',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: compressedImageInfo!['sizeBytes'] < 1024 * 1024 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Retrieved Image from Firestore
            if (uploadedImageId != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '☁️ Retrieved from Firestore',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FirestoreImageWidget(
                            imageId: uploadedImageId,
                            fit: BoxFit.cover,
                            placeholder: Center(child: CircularProgressIndicator()),
                            errorWidget: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Image ID: $uploadedImageId'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
