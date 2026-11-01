/// A medicine product from the bundled medicine database.
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.salt,
    required this.strength,
    required this.form,
    required this.pack,
    required this.manufacturer,
    required this.mrp,
    this.isGeneric = false,
  });

  final String id;
  final String name;
  final String salt;
  final String strength;
  final String form;
  final String pack;
  final String manufacturer;
  final double mrp;
  final bool isGeneric;

  /// Same active ingredients, strength and dosage form -> interchangeable
  /// (subject to a doctor's/pharmacist's advice).
  String get compositionKey =>
      '${salt.toLowerCase()}|${strength.toLowerCase()}|${form.toLowerCase()}';

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'] as String,
        name: json['name'] as String,
        salt: json['salt'] as String,
        strength: json['strength'] as String,
        form: json['form'] as String,
        pack: json['pack'] as String,
        manufacturer: json['manufacturer'] as String,
        mrp: (json['mrp'] as num).toDouble(),
        isGeneric: json['isGeneric'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) => other is Medicine && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
