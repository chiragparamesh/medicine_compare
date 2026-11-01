/// App-wide constants.
class AppConstants {
  static const appName = 'MediCompare';
  static const tagline = 'Snap a prescription. Pay the lowest price.';

  /// Feature modules from the brief. Each one lives in `lib/features/<name>/`.
  static const modules = <AppModule>[
    AppModule('Prescription Scan', 'Camera / gallery picker for the prescription photo'),
    AppModule('OCR', 'OCR service interface + placeholder (TrOCR later)'),
    AppModule('Cart', 'Editable medicine cart the user confirms'),
    AppModule('Pricing', 'Bundled mock prices for 1mg, PharmEasy, Netmeds, Apollo 24/7, Truemeds'),
    AppModule('Coupons', 'Coupon rule engine: percent, flat, max cap, min order, first order'),
    AppModule('Results', 'Results screen ranking platforms + cheaper generic'),
  ];
}

class AppModule {
  const AppModule(this.title, this.description);
  final String title;
  final String description;
}
