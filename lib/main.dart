import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(CartController());
  runApp(const RatneshGoldApp());
}
