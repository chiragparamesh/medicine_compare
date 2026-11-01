import 'dart:typed_data';

import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/cart_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prescription_scan/presentation/scan_screen.dart';
import '../../features/results/presentation/results_screen.dart';

class AppRoutes {
  static const home = '/';
  static const scan = '/scan';
  static const cart = '/cart';
  static const results = '/results';
}

/// Central route table.
GoRouter createRouter() => GoRouter(
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: AppRoutes.scan,
          builder: (_, state) => ScanScreen(imageBytes: state.extra as Uint8List?),
        ),
        GoRoute(path: AppRoutes.cart, builder: (_, _) => const CartScreen()),
        GoRoute(path: AppRoutes.results, builder: (_, _) => const ResultsScreen()),
      ],
    );
