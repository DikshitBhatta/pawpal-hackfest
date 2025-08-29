import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pet_care/DataBase.dart';

class FirestoreImageWidget extends StatefulWidget {
  final String? imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirestoreImageWidget({
    Key? key,
    this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  _FirestoreImageWidgetState createState() => _FirestoreImageWidgetState();
}

class _FirestoreImageWidgetState extends State<FirestoreImageWidget> {
  Uint8List? imageBytes;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(FirestoreImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageId == null || widget.imageId!.isEmpty) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final base64String = await DataBase.getImageBase64(widget.imageId!);
      
      if (base64String != null && base64String.isNotEmpty) {
        final bytes = base64Decode(base64String);
        setState(() {
          imageBytes = bytes;
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            child: Center(
              child: Lottie.asset(
                'assets/Animations/AnimalcareLoading.json',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
          );
    }

    if (hasError || imageBytes == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: Icon(
              Icons.error_outline,
              color: Colors.grey[600],
              size: 40,
            ),
          );
    }

    return Image.memory(
      imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
