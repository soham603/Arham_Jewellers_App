enum CurrentAppState {
  INITIAL,
  LOADING,
  SUCCESS,
  ERROR
}

enum SortOption {
  nameAsc,
  weightAsc,
  weightDesc,
  newest,
  oldest,
  priceAsc,
  priceDesc,
}

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.nameAsc:
        return 'Name A–Z';
      case SortOption.weightAsc:
        return 'Weight Low→High';
      case SortOption.weightDesc:
        return 'Weight High→Low';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.priceAsc:
        return 'Price Low→High';
      case SortOption.priceDesc:
        return 'Price High→Low';
    }
  }
}