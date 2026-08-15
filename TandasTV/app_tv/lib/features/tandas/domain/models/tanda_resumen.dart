class TandaResumen {
  final String id;
  final String nombre;
  final String estado;
  final int numMiembrosActuales;
  final int numParticipantes;

  TandaResumen({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.numMiembrosActuales,
    required this.numParticipantes,
  });

  factory TandaResumen.fromJson(Map<String, dynamic> json) {
    return TandaResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      numMiembrosActuales: json['numMiembrosActuales'] as int? ?? 0,
      numParticipantes: json['numParticipantes'] as int? ?? 0,
    );
  }
}
