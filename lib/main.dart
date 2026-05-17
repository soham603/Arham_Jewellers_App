import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'app/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  Get.put(() => CartController());
  runApp(const RatneshGoldApp());
}
