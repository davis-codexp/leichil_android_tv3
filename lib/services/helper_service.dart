import 'dart:convert';
import "dart:typed_data";
import 'package:flutter/material.dart';

class HelperService {
    static Uint8List decodeImage(String rawImage) {
        try {
            final imgStr = rawImage.contains(",") ? rawImage.split(",").last : rawImage;        
            final String sanitized = imgStr.replaceAll(RegExp(r'\s+'), "");
            return base64Decode(sanitized);
        } catch(err) {
            debugPrint("$err");
            return base64Decode("test");
        }
    }

    static String imageURL(dynamic value) {
        final image = value?.toString().trim() ?? '';
        if (image.isEmpty) return '';
        if (image.startsWith('http://') || image.startsWith('https://')) {
            return image;
        }
        if (image.startsWith('/')) return 'https://assets.leichiltv.com$image';
        return 'https://assets.leichiltv.com/$image';
    }
}
