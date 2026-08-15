double _parseMonto(dynamic value) => double.tryParse(value?.toString() ?? '0') ?? 0.0;

class TandaInfo {
  final String id;
  final String nombre;
  final double montoAportacion;
  final String frecuencia;
  final int numParticipantes;
  final String estado;

  TandaInfo({
    required this.id,
    required this.nombre,
    required this.montoAportacion,
    required this.frecuencia,
    required this.numParticipantes,
    required this.estado,
  });

  factory TandaInfo.fromJson(Map<String, dynamic> json) {
    return TandaInfo(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      montoAportacion: _parseMonto(json['montoAportacion']),
      frecuencia: json['frecuencia'] as String? ?? '',
      numParticipantes: json['numParticipantes'] as int? ?? 0,
      estado: json['estado'] as String? ?? '',
    );
  }
}

class Beneficiario {
  final String id;
  final String nombre;
  final String? fotoPerfil;

  Beneficiario({required this.id, required this.nombre, this.fotoPerfil});

  factory Beneficiario.fromJson(Map<String, dynamic> json) {
    return Beneficiario(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Sin asignar',
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }
}

class PagoPublico {
  final String miembroTandaId;
  final String nombre;
  final String? fotoPerfil;
  final String estado;
  final double monto;

  PagoPublico({
    required this.miembroTandaId,
    required this.nombre,
    this.fotoPerfil,
    required this.estado,
    required this.monto,
  });

  factory PagoPublico.fromJson(Map<String, dynamic> json) {
    return PagoPublico(
      miembroTandaId: json['miembroTandaId'] as String,
      nombre: json['nombre'] as String? ?? 'Desconocido',
      fotoPerfil: json['fotoPerfil'] as String?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      monto: _parseMonto(json['monto']),
    );
  }
}

class ResumenPagos {
  final int total;
  final int pagados;
  final int reportados;
  final int pendientes;
  final int atrasados;

  ResumenPagos({
    required this.total,
    required this.pagados,
    required this.reportados,
    required this.pendientes,
    required this.atrasados,
  });

  factory ResumenPagos.fromJson(Map<String, dynamic> json) {
    return ResumenPagos(
      total: json['total'] as int? ?? 0,
      pagados: json['pagados'] as int? ?? 0,
      reportados: json['reportados'] as int? ?? 0,
      pendientes: json['pendientes'] as int? ?? 0,
      atrasados: json['atrasados'] as int? ?? 0,
    );
  }
}

class CicloPublico {
  final int numeroCiclo;
  final DateTime fechaLimite;
  final bool cerrado;
  final double montoTotalCiclo;
  final Beneficiario beneficiario;
  final List<PagoPublico> pagos;
  final ResumenPagos resumen;

  CicloPublico({
    required this.numeroCiclo,
    required this.fechaLimite,
    required this.cerrado,
    required this.montoTotalCiclo,
    required this.beneficiario,
    required this.pagos,
    required this.resumen,
  });

  factory CicloPublico.fromJson(Map<String, dynamic> json) {
    final pagosList = (json['pagos'] as List? ?? [])
        .map((p) => PagoPublico.fromJson(p as Map<String, dynamic>))
        .toList();
    return CicloPublico(
      numeroCiclo: json['numeroCiclo'] as int? ?? 1,
      fechaLimite: DateTime.tryParse(json['fechaLimite'] as String? ?? '') ?? DateTime.now(),
      cerrado: json['cerrado'] as bool? ?? false,
      montoTotalCiclo: _parseMonto(json['montoTotalCiclo']),
      beneficiario: Beneficiario.fromJson(json['beneficiario'] as Map<String, dynamic>? ?? {'id': '', 'nombre': 'Sin asignar'}),
      pagos: pagosList,
      resumen: ResumenPagos.fromJson(json['resumen'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PantallaPublica {
  final TandaInfo tanda;
  final CicloPublico? cicloActual;

  PantallaPublica({required this.tanda, this.cicloActual});

  factory PantallaPublica.fromJson(Map<String, dynamic> json) {
    return PantallaPublica(
      tanda: TandaInfo.fromJson(json['tanda'] as Map<String, dynamic>),
      cicloActual: json['cicloActual'] != null
          ? CicloPublico.fromJson(json['cicloActual'] as Map<String, dynamic>)
          : null,
    );
  }
}
