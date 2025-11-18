class ParaderoModel {
  final String id;
  final String codigo;
  final String nombre;
  final List<String> micros;

  ParaderoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.micros,
  });

  String get nombreCompleto => '$codigo - $nombre';

  factory ParaderoModel.fromJson(Map<String, dynamic> json) {
    return ParaderoModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      micros: (json['micros'] as List).map((m) => m.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'micros': micros,
    };
  }
}