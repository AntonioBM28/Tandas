import '../domain/models/tanda.dart';
import '../domain/models/tanda_detalle.dart';
import 'mock_tandas.dart';

final Map<String, TandaDetalle> mockTandasDetalle = {
  // 1. Tanda en ARMANDO donde el usuario es ADMIN
  't1': TandaDetalle(
    tandaBase: mockTandas.firstWhere((t) => t.id == 't1'),
    miembros: [
      Miembro(id: 'm1', nombre: 'Antonio García (Tú)', rol: TandaRol.admin, estado: MiembroEstado.activo, turnoOrden: 1),
      Miembro(id: 'm2', nombre: 'María López', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: null),
      Miembro(id: 'm3', nombre: 'Carlos Ruiz', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: null),
    ],
    cicloActual: null,
  ),
  
  // 2. Tanda ACTIVA donde el usuario es ADMIN (pagos mixtos)
  't4': TandaDetalle(
    tandaBase: mockTandas.firstWhere((t) => t.id == 't4'),
    miembros: [
      Miembro(id: 'm1', nombre: 'Antonio García (Tú)', rol: TandaRol.admin, estado: MiembroEstado.activo, turnoOrden: 2),
      Miembro(id: 'm4', nombre: 'Ana Gómez', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 1),
      Miembro(id: 'm5', nombre: 'Luis Torres', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 3),
      Miembro(id: 'm6', nombre: 'Sofía Castro', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 4),
    ],
    cicloActual: Ciclo(
      numeroCiclo: 2,
      fechaLimite: DateTime.now().add(const Duration(days: 3)),
      nombreBeneficiario: 'Antonio García (Tú)',
      montoTotalCiclo: 6000.0,
      pagos: [
        Pago(nombreMiembro: 'Ana Gómez', estado: PagoEstado.pagado),
        Pago(nombreMiembro: 'Luis Torres', estado: PagoEstado.atrasado),
        Pago(nombreMiembro: 'Sofía Castro', estado: PagoEstado.pendiente),
      ],
    ),
  ),
  
  // 3. Tanda ACTIVA donde el usuario es MIEMBRO (sin botones de gestión)
  't2': TandaDetalle(
    tandaBase: mockTandas.firstWhere((t) => t.id == 't2'),
    miembros: [
      Miembro(id: 'm7', nombre: 'Pedro Sánchez', rol: TandaRol.admin, estado: MiembroEstado.activo, turnoOrden: 1),
      Miembro(id: 'm1', nombre: 'Antonio García (Tú)', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 2),
      Miembro(id: 'm8', nombre: 'Laura Díaz', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 3),
      Miembro(id: 'm9', nombre: 'Jorge Luna', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 4),
      Miembro(id: 'm10', nombre: 'Carmen Silva', rol: TandaRol.miembro, estado: MiembroEstado.activo, turnoOrden: 5),
    ],
    cicloActual: Ciclo(
      numeroCiclo: 1,
      fechaLimite: DateTime.now().add(const Duration(days: 1)),
      nombreBeneficiario: 'Pedro Sánchez',
      montoTotalCiclo: 5000.0,
      pagos: [
        Pago(nombreMiembro: 'Antonio García (Tú)', estado: PagoEstado.pagado),
        Pago(nombreMiembro: 'Laura Díaz', estado: PagoEstado.pendiente),
        Pago(nombreMiembro: 'Jorge Luna', estado: PagoEstado.pendiente),
        Pago(nombreMiembro: 'Carmen Silva', estado: PagoEstado.pagado),
      ],
    ),
  ),
};

// Fallback por si tocan otra tanda (t3, t5, t6) en el Home
TandaDetalle getMockTandaDetalle(String id) {
  if (mockTandasDetalle.containsKey(id)) {
    return mockTandasDetalle[id]!;
  }
  final base = mockTandas.firstWhere((t) => t.id == id, orElse: () => mockTandas.first);
  return TandaDetalle(
    tandaBase: base,
    miembros: [
      Miembro(id: 'm1', nombre: 'Antonio García (Tú)', rol: base.rolDelUsuario, estado: MiembroEstado.activo, turnoOrden: 1),
    ],
  );
}
