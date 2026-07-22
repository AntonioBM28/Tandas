-- CreateEnum
CREATE TYPE "RolTanda" AS ENUM ('ADMIN', 'MIEMBRO');

-- CreateEnum
CREATE TYPE "EstadoMiembro" AS ENUM ('ACTIVO', 'INACTIVO', 'EXPULSADO');

-- CreateEnum
CREATE TYPE "FrecuenciaTanda" AS ENUM ('SEMANAL', 'QUINCENAL', 'MENSUAL');

-- CreateEnum
CREATE TYPE "EstadoTanda" AS ENUM ('ARMANDO', 'ACTIVA', 'FINALIZADA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "EstadoPago" AS ENUM ('PENDIENTE', 'PAGADO', 'ATRASADO');

-- CreateEnum
CREATE TYPE "EstadoInvitacion" AS ENUM ('ACTIVA', 'USADA', 'EXPIRADA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "TipoNotificacion" AS ENUM ('RECORDATORIO_PAGO', 'PAGO_RECIBIDO', 'TURNO_PROXIMO', 'TANDA_INICIADA', 'TANDA_FINALIZADA', 'MIEMBRO_UNIDO');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "telefono" TEXT,
    "foto_perfil" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tokens_refresco" (
    "id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "revocado" BOOLEAN NOT NULL DEFAULT false,
    "expira_en" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tokens_refresco_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tandas" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "descripcion" TEXT,
    "monto_aportacion" DECIMAL(10,2) NOT NULL,
    "frecuencia" "FrecuenciaTanda" NOT NULL,
    "num_participantes" INTEGER NOT NULL,
    "fecha_inicio" TIMESTAMP(3),
    "estado" "EstadoTanda" NOT NULL DEFAULT 'ARMANDO',
    "admin_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tandas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "miembros_tanda" (
    "id" TEXT NOT NULL,
    "tanda_id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "rol" "RolTanda" NOT NULL DEFAULT 'MIEMBRO',
    "turno_orden" INTEGER,
    "estado" "EstadoMiembro" NOT NULL DEFAULT 'ACTIVO',
    "fecha_union" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "miembros_tanda_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invitaciones_tanda" (
    "id" TEXT NOT NULL,
    "tanda_id" TEXT NOT NULL,
    "codigo" TEXT NOT NULL,
    "creado_por_id" TEXT NOT NULL,
    "estado" "EstadoInvitacion" NOT NULL DEFAULT 'ACTIVA',
    "usos_maximos" INTEGER NOT NULL DEFAULT 1,
    "usos_actuales" INTEGER NOT NULL DEFAULT 0,
    "expira_en" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invitaciones_tanda_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ciclos_pago" (
    "id" TEXT NOT NULL,
    "tanda_id" TEXT NOT NULL,
    "numero_ciclo" INTEGER NOT NULL,
    "fecha_limite" TIMESTAMP(3) NOT NULL,
    "turno_beneficiario_id" TEXT NOT NULL,
    "cerrado" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ciclos_pago_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pagos" (
    "id" TEXT NOT NULL,
    "ciclo_pago_id" TEXT NOT NULL,
    "miembro_tanda_id" TEXT NOT NULL,
    "monto" DECIMAL(10,2) NOT NULL,
    "fecha_pago" TIMESTAMP(3),
    "estado" "EstadoPago" NOT NULL DEFAULT 'PENDIENTE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pagos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notificaciones" (
    "id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "tipo" "TipoNotificacion" NOT NULL,
    "mensaje" TEXT NOT NULL,
    "leido" BOOLEAN NOT NULL DEFAULT false,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE INDEX "tokens_refresco_usuario_id_idx" ON "tokens_refresco"("usuario_id");

-- CreateIndex
CREATE UNIQUE INDEX "miembros_tanda_tanda_id_usuario_id_key" ON "miembros_tanda"("tanda_id", "usuario_id");

-- CreateIndex
CREATE UNIQUE INDEX "miembros_tanda_tanda_id_turno_orden_key" ON "miembros_tanda"("tanda_id", "turno_orden");

-- CreateIndex
CREATE UNIQUE INDEX "invitaciones_tanda_codigo_key" ON "invitaciones_tanda"("codigo");

-- CreateIndex
CREATE INDEX "invitaciones_tanda_tanda_id_idx" ON "invitaciones_tanda"("tanda_id");

-- CreateIndex
CREATE UNIQUE INDEX "ciclos_pago_tanda_id_numero_ciclo_key" ON "ciclos_pago"("tanda_id", "numero_ciclo");

-- CreateIndex
CREATE UNIQUE INDEX "pagos_ciclo_pago_id_miembro_tanda_id_key" ON "pagos"("ciclo_pago_id", "miembro_tanda_id");

-- CreateIndex
CREATE INDEX "notificaciones_usuario_id_leido_idx" ON "notificaciones"("usuario_id", "leido");

-- AddForeignKey
ALTER TABLE "tokens_refresco" ADD CONSTRAINT "tokens_refresco_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tandas" ADD CONSTRAINT "tandas_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "miembros_tanda" ADD CONSTRAINT "miembros_tanda_tanda_id_fkey" FOREIGN KEY ("tanda_id") REFERENCES "tandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "miembros_tanda" ADD CONSTRAINT "miembros_tanda_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitaciones_tanda" ADD CONSTRAINT "invitaciones_tanda_tanda_id_fkey" FOREIGN KEY ("tanda_id") REFERENCES "tandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitaciones_tanda" ADD CONSTRAINT "invitaciones_tanda_creado_por_id_fkey" FOREIGN KEY ("creado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ciclos_pago" ADD CONSTRAINT "ciclos_pago_tanda_id_fkey" FOREIGN KEY ("tanda_id") REFERENCES "tandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ciclos_pago" ADD CONSTRAINT "ciclos_pago_turno_beneficiario_id_fkey" FOREIGN KEY ("turno_beneficiario_id") REFERENCES "miembros_tanda"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_ciclo_pago_id_fkey" FOREIGN KEY ("ciclo_pago_id") REFERENCES "ciclos_pago"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_miembro_tanda_id_fkey" FOREIGN KEY ("miembro_tanda_id") REFERENCES "miembros_tanda"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
