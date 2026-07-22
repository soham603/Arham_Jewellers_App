const orderStatuses = [
  ('PENDING', 'Pending'),
  ('APPROVED', 'Approved'),
  ('ASSIGNED', 'Assigned'),
  ('COMPLETED', 'Completed'),
  ('REJECTED', 'Rejected'),
  ('CANCELLED_BY_USER', 'Cancelled'),
];

enum CurrentAppState {
  INITIAL,
  LOADING,
  SUCCESS,
  ERROR
}

enum LayoutType { grid, list, fullScreen }

extension LayoutTypeLabel on LayoutType {
  String get label {
    switch (this) {
      case LayoutType.grid:
        return 'Grid';
      case LayoutType.list:
        return 'List';
      case LayoutType.fullScreen:
        return 'Full Width';
    }
  }
}

enum SortOption {
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