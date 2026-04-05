import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/restServices/apiService.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

BaseHttpService baseHttpService = BaseHttpService();
final httpClient = baseHttpService.client;

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();