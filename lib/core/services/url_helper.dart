class UrlHelper {
  static const String baseUrl = 'https://prakrutitech.xyz/gaurang/';

  static String getMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty || relativePath == 'ghfd') {
      return '';
    }

    if (relativePath.startsWith('http')) {
      return relativePath;
    }

    String path = relativePath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('uploads/')) {
      return '$baseUrl$path';
    }

    return '$baseUrl/uploads/$path';
  }
}