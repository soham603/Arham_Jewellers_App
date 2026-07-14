String cleanCategoryName(String name) {
  return name
      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
      .replaceAll(RegExp(r'collection', caseSensitive: false), '')
      .trim();
}