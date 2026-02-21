class ImageUtils {
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    // Use the base URL from NetworkModule if possible, or hardcode it
    // NetworkModule._baseUrl is private, so I'll define it here or make it public in NetworkModule
    const String baseUrl = "https://drawai-api.drawai.site/";

    final cleanPath = path.startsWith("/") ? path.substring(1) : path;
    return "$baseUrl$cleanPath";
  }
}
