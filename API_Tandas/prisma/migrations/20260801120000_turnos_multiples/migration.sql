-- Permite que un miembro tenga más de un turno en la misma tanda.
-- Antes: miembros_tanda.turno_orden (1 turno por miembro, como máximo).
-- Ahora: tabla turnos_tanda (N turnos por miembro), y pagos genera una
-- fila por cada turno (no una por miembro) para que quien tiene más
-- turnos aporte y cobre proporcionalmente más veces.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Crear tabla turnos_tanda
CREATE TABLE "turnos_tanda" (
    "id" TEXT NOT NULL,
    "tanda_id" TEXT NOT NULL,
    "turno_orden" INTEGER NOT NULL,
    "miembro_tanda_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "turnos_tanda_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "turnos_tanda_tanda_id_turno_orden_key" ON "turnos_tanda"("tanda_id", "turno_orden");

ALTER TABLE "turnos_tanda" ADD CONSTRAINT "turnos_tanda_tanda_id_fkey" FOREIGN KEY ("tanda_id") REFERENCES "tandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "turnos_tanda" ADD CONSTRAINT "turnos_tanda_miembro_tanda_id_fkey" FOREIGN KEY ("miembro_tanda_id") REFERENCES "miembros_tanda"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 2. Backfill: migrar los turnos ya asignados en miembros_tanda.turno_orden
INSERT INTO "turnos_tanda" ("id", "tanda_id", "turno_orden", "miembro_tanda_id", "created_at")
SELECT gen_random_uuid()::text, "tanda_id", "turno_orden", "id", now()
FROM "miembros_tanda"
WHERE "turno_orden" IS NOT NULL;

-- 3. Agregar turno_tanda_id a pagos y backfillearlo con el turno propio de
--    cada miembro dentro de la tanda a la que pertenece ese ciclo de pago
ALTER TABLE "pagos" ADD COLUMN "turno_tanda_id" TEXT;

UPDATE "pagos" p
SET "turno_tanda_id" = t."id"
FROM "turnos_tanda" t, "ciclos_pago" c
WHERE c."id" = p."ciclo_pago_id"
  AND t."miembro_tanda_id" = p."miembro_tanda_id"
  AND t."tanda_id" = c."tanda_id";

-- Salvaguarda: si algún pago de datos de prueba no encontró turno
-- correspondiente (no debería pasar en un flujo normal), se elimina en
-- vez de dejar una fila con turno_tanda_id nulo.
DELETE FROM "pagos" WHERE "turno_tanda_id" IS NULL;

ALTER TABLE "pagos" ALTER COLUMN "turno_tanda_id" SET NOT NULL;
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_turno_tanda_id_fkey" FOREIGN KEY ("turno_tanda_id") REFERENCES "turnos_tanda"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 4. Reemplazar el unique constraint viejo de pagos (uno por miembro por
--    ciclo) por uno basado en turno (uno por turno por ciclo)
DROP INDEX IF EXISTS "pagos_ciclo_pago_id_miembro_tanda_id_key";
CREATE UNIQUE INDEX "pagos_ciclo_pago_id_turno_tanda_id_key" ON "pagos"("ciclo_pago_id", "turno_tanda_id");

-- 5. Quitar turno_orden de miembros_tanda (y su unique constraint viejo);
--    ahora vive en turnos_tanda
DROP INDEX IF EXISTS "miembros_tanda_tanda_id_turno_orden_key";
ALTER TABLE "miembros_tanda" DROP COLUMN IF EXISTS "turno_orden";
