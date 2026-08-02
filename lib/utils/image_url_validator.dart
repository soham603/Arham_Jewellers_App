bool isValidImageUrl(String? url) {
  return url != null &&
      url.trim().isNotEmpty &&
      Uri.tryParse(url)?.hasAbsolutePath == true;
}
