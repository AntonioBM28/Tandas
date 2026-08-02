-- Agrega el estado intermedio "REPORTADO": el miembro dice que ya pagó,
-- pero queda pendiente de que el admin lo confirme como PAGADO.
ALTER TYPE "EstadoPago" ADD VALUE 'REPORTADO';
