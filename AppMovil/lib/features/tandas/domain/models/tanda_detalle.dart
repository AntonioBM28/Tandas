import 'tanda.dart';

enum MiembroEstado {
  activo,
  inactivo,
  expulsado;

  static MiembroEstado fromString(String str) {
    switch (str.toUpperCase()) {
      case 'ACTIVO': return MiembroEstado.activo;
      case 'INACTIVO': return MiembroEstado.inactivo;
      case 'EXPULSADO': return MiembroEstado.expulsado;
      default: return MiembroEstado.activo;
    }
  }
}

class Miembro {
  final String id;
  final String nombre;
  final String? fotoUrl;
  final TandaRol rol;
  final int? turnoOrden;
  final MiembroEstado estado;

  Miembro({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    required this.rol,
    this.turnoOrden,
    required this.estado,
  });

  factory Miembro.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] ?? {};
    return Miembro(
      id: json['id'] ?? '',
      nombre: usuario['nombre'] ?? 'Desconocido',
      fotoUrl: usuario['fotoPerfil'],
      rol: TandaRol.fromString(json['rol'] ?? ''),
      turnoOrden: json['turnoOrden'],
      estado: MiembroEstado.fromString(json['estado'] ?? ''),
    );
  }
}

enum PagoEstado {
  pendiente,
  pagado,
  atrasado;

  static PagoEstado fromString(String str) {
    switch (str.toUpperCase()) {
      case 'PENDIENTE': return PagoEstado.pendiente;
      case 'PAGADO': return PagoEstado.pagado;
      case 'ATRASADO': return PagoEstado.atrasado;
      default: return PagoEstado.pendiente;
    }
  }
}

class Pago {
  final String nombreMiembro;
  final PagoEstado estado;

  Pago({
    required this.nombreMiembro,
    required this.estado,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      nombreMiembro: json['nombreMiembro'] ?? 'Desconocido',
      estado: PagoEstado.fromString(json['estado'] ?? ''),
    );
  }
}

class Ciclo {
  final int numeroCiclo;
  final DateTime fechaLimite;
  final String nombreBeneficiario;
  final double montoTotalCiclo;
  final List<Pago> pagos;

  Ciclo({
    required this.numeroCiclo,
    required this.fechaLimite,
    required this.nombreBeneficiario,
    required this.montoTotalCiclo,
    required this.pagos,
  });

  factory Ciclo.fromJson(Map<String, dynamic> json) {
    var list = json['pagos'] as List? ?? [];
    List<Pago> pagosList = list.map((i) => Pago.fromJson(i)).toList();

    return Ciclo(
      numeroCiclo: json['numeroCiclo'] ?? 1,
      fechaLimite: json['fechaLimite'] != null 
          ? DateTime.tryParse(json['fechaLimite']) ?? DateTime.now() 
          : DateTime.now(),
      nombreBeneficiario: json['nombreBeneficiario'] ?? 'Sin asignar',
      montoTotalCiclo: double.tryParse(json['montoTotalCiclo']?.toString() ?? '0') ?? 0.0,
      pagos: pagosList,
    );
  }
}

class TandaDetalle {
  final Tanda tandaBase;
  final List<Miembro> miembros;
  final Ciclo? cicloActual;

  TandaDetalle({
    required this.tandaBase,
    required this.miembros,
    this.cicloActual,
  });

  factory TandaDetalle.fromJson(Map<String, dynamic> json, String currentUserId) {
    var list = json['miembros'] as List? ?? [];
    List<Miembro> miembrosList = list.map((i) => Miembro.fromJson(i)).toList();

    // Encontrar mi rol
    final miMiembro = list.firstWhere(
      (m) => m['usuario'] != null && m['usuario']['id'] == currentUserId, 
      orElse: () => null
    );
    final miRol = miMiembro != null ? miMiembro['rol'] : (json['adminId'] == currentUserId ? 'ADMIN' : 'MIEMBRO');

    // Mapear Tanda base
    final tandaBase = Tanda(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      montoAportacion: double.tryParse(json['montoAportacion']?.toString() ?? '0') ?? 0.0,
      frecuencia: TandaFrecuencia.fromString(json['frecuencia'] ?? ''),
      numParticipantes: json['numParticipantes'] ?? 0,
      numMiembrosActuales: miembrosList.length,
      estado: TandaEstado.fromString(json['estado'] ?? ''),
      rolDelUsuario: TandaRol.fromString(miRol ?? ''),
    );

    // Mapear ciclo actual (si lo manda el backend, aquí lo adaptamos simple por ahora)
    Ciclo? cicloActual;
    if (json['cicloActual'] != null) {
      cicloActual = Ciclo.fromJson(json['cicloActual']);
    } else if (json['ciclos'] != null && (json['ciclos'] as List).isNotEmpty) {
      final ultimo = (json['ciclos'] as List).last;
      cicloActual = Ciclo.fromJson(ultimo);
    }

    return TandaDetalle(
      tandaBase: tandaBase,
      miembros: miembrosList,
      cicloActual: cicloActual,
    );
  }
}
