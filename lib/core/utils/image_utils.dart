import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageUtils {
  static Future<XFile?> compressImage(XFile file) async {
    if (kIsWeb) return file; // Skip compression on web for simplicity
    
    final targetPath = file.path + "_compressed.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
    );

    return result;
  }
}
