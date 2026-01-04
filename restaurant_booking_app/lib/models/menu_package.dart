class MenuPackage {
  final int? id;
  final String name;
  final String description;
  final double pricePerGuest;
  final String imageUrl;

  MenuPackage({
    this.id,
    required this.name,
    required this.description,
    required this.pricePerGuest,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerGuest': pricePerGuest,
      'imageUrl': imageUrl,
    };
  }

  factory MenuPackage.fromMap(Map<String, dynamic> map) {
    return MenuPackage(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      pricePerGuest: map['pricePerGuest'] as double,
      imageUrl: map['imageUrl'] as String,
    );
  }

  MenuPackage copyWith({
    int? id,
    String? name,
    String? description,
    double? pricePerGuest,
    String? imageUrl,
  }) {
    return MenuPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
