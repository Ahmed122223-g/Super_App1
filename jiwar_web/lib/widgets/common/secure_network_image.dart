import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';

class SecureNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SecureNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Icon(Icons.error);
    }
    
    // Construct Auth Headers
    final headers = <String, String>{};
    final token = ApiService().token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token'; // Fixed: Correct interpolation
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? 
          Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.broken_image);
      },
    );
  }
}

/// Provider for DecorationImage (e.g. CircleAvatar, Container decoration)
ImageProvider secureNetworkImageProvider(String url) {
  final headers = <String, String>{};
  final token = ApiService().token;
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return NetworkImage(url, headers: headers);
}
