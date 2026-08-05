String cleanCategoryName(String name) {
  return name
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'collection', caseSensitive: false), '')
      .trim();
}