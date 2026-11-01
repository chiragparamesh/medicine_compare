import '../../catalog/domain/medicine.dart';

/// One line in the cart: a medicine and how many packs.
class CartItem {
  const CartItem({required this.medicine, this.quantity = 1});

  final Medicine medicine;
  final int quantity;

  CartItem copyWith({Medicine? medicine, int? quantity}) => CartItem(
        medicine: medicine ?? this.medicine,
        quantity: quantity ?? this.quantity,
      );
}
