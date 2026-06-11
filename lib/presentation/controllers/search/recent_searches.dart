import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesController extends GetxController {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;

  final recentSearches = <String>[].obs;
  List<String> get recentSearchesList => recentSearches;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesKey) ?? [];
      recentSearches.value = saved;
    } catch (e) {
      Logger.error("RecentSearchesController", "loadRecentSearches error: $e");
    }
  }

  Future<void> addToRecentSearches(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_recentSearchesKey) ?? [];
      final updated = [
        query,
        ...existing.where((s) => s.toLowerCase() != query.toLowerCase()),
      ].take(_maxRecentSearches).toList();

      recentSearches.value = updated;
      await prefs.setStringList(_recentSearchesKey, updated);
    } catch (e) {
      Logger.error("RecentSearchesController", "_saveRecentSearch error: $e");
    }
  }

  Future<void> removeFromRecentSearches(String query) async {
    recentSearches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, recentSearches.toList());
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
