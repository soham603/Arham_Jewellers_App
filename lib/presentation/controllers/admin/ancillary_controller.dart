import 'package:get/get.dart';

class AncillaryController extends GetxController {
  Future<String?> fetchAncillaryHtml(String category) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulating network
      return "<h2>Edit the $category page</h2><p>This is the HTML content fetched from the API.</p>";
    } catch (e) {
      print("Error fetching $category: $e");
      return null;
    }
  }

  Future<bool> updateAncillaryHtml(
    String category,
    String newHtmlContent,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulating network
      return true;
    } catch (e) {
      print("Error updating $category: $e");
      return false;
    }
  }
}
