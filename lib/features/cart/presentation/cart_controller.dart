import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/medicine.dart';
import '../domain/cart_item.dart';

/// The editable cart. Adding an existing medicine increases its quantity.
class CartController extends Notifier<List<CartItem>> {
  static const maxQuantity = 20;

  @override
  List<CartItem> build() => const [];

  void add(Medicine medicine, {int quantity = 1}) {
    final i = state.indexWhere((c) => c.medicine.id == medicine.id);
    if (i == -1) {
      state = [...state, CartItem(medicine: medicine, quantity: quantity.clamp(1, maxQuantity))];
    } else {
      setQuantity(medicine.id, state[i].quantity + quantity);
    }
  }

  void addAll(Iterable<Medicine> medicines) {
    for (final m in medicines) {
      add(m);
    }
  }

  void setQuantity(String medicineId, int quantity) {
    if (quantity <= 0) return remove(medicineId);
    state = [
      for (final c in state)
        if (c.medicine.id == medicineId) c.copyWith(quantity: quantity.clamp(1, maxQuantity)) else c,
    ];
  }

  void remove(String medicineId) {
    state = [for (final c in state) if (c.medicine.id != medicineId) c];
  }

  /// Swap a medicine (e.g. wrong OCR match, or brand -> generic), keeping quantity.
  /// If the replacement is already in the cart, the quantities are merged.
  void replace(String oldId, Medicine replacement) {
    final old = state.where((c) => c.medicine.id == oldId).firstOrNull;
    if (old == null || oldId == replacement.id) return;
    remove(oldId);
    add(replacement, quantity: old.quantity);
  }

  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);
