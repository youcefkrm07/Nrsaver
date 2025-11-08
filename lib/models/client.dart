class ClientModel {
  final int id; // Hive key surrogate when using auto-increment
  final String name;
  final String mobile4g;
  final String fibre;

  const ClientModel({
    required this.id,
    required this.name,
    required this.mobile4g,
    required this.fibre,
  });

  ClientModel copyWith({int? id, String? name, String? mobile4g, String? fibre}) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile4g: mobile4g ?? this.mobile4g,
      fibre: fibre ?? this.fibre,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mobile4g': mobile4g,
        'fibre': fibre,
      };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        id: map['id'] as int,
        name: (map['name'] ?? '') as String,
        mobile4g: (map['mobile4g'] ?? '') as String,
        fibre: (map['fibre'] ?? '') as String,
      );
}
