enum Karat { k18, k20, k22 }

extension KaratExtension on Karat {
  String get slug {
    switch (this) {
      case Karat.k18:
        return '18k';
      case Karat.k20:
        return '20k';
      case Karat.k22:
        return '22k';
    }
  }

  String get displayName {
    switch (this) {
      case Karat.k18:
        return '18K';
      case Karat.k20:
        return '20K';
      case Karat.k22:
        return '22K';
    }
  }

  int get touchValue => KaratConstants.touchValueFor(displayName);

  String get purityPercent => KaratConstants.percentLabel(displayName);
}

abstract class KaratConstants {
  static const Map<String, int> touchValues = {
    '9K': 38,
    '14K': 60,
    '18K': 76,
    '20K': 84,
    '22K': 92,
    '24K': 100,
  };

  static const List<String> all = ['9K', '14K', '18K', '20K', '22K', '24K'];
  static const List<String> common = ['18K', '20K', '22K'];

  static int touchValueFor(String karat) => touchValues[karat] ?? 0;

  static String? purityValueFor(String karat) {
    final value = touchValues[karat];
    return value != null ? value.toString() : null;
  }

  static String percentLabel(String karat) => '${touchValueFor(karat)}%';

  static String formattedPurity(String karat) {
    final touch = touchValueFor(karat);
    final num = karatNumber(karat);
    if (num == null) return '';
    return '$touch ($num K)';
  }

  static int? karatNumber(String karat) {
    final match = RegExp(r'(\d+)').firstMatch(karat);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static int? karatFromTouchValue(int touch) {
    if (touch >= 995 && touch <= 1005) return 24;
    if (touch >= 915 && touch <= 925) return 22;
    if (touch >= 835 && touch <= 845) return 20;
    if (touch >= 755 && touch <= 765) return 18;
    if (touch >= 595 && touch <= 605) return 14;
    if (touch >= 375 && touch <= 385) return 9;
    return null;
  }

  static String touchValueToString(String karat) =>
      touchValueFor(karat).toString();

  static const List<Map<String, String>> commonOptions = [
    {'label': '18K', 'percent': '76%'},
    {'label': '20K', 'percent': '84%'},
    {'label': '22K', 'percent': '92%'},
  ];

  static const List<String> caratChipOptions = [
    '9K  (38%)',
    '14K (60%)',
    '18K (76%)',
    '20K (84%)',
    '22K (92%)',
    '24K (100%)',
  ];
}
