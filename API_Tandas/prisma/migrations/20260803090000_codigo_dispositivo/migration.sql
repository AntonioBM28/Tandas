-- Vinculación de dispositivos sin teclado cómodo (el reloj) vía código de
-- 6 dígitos: el reloj pide un código, el usuario ya logueado en el celular
-- lo confirma, y el reloj recibe una sesión real.

CREATE TYPE "EstadoCodigoDispositivo" AS ENUM ('PENDIENTE', 'CONFIRMADO');

CREATE TABLE "codigos_dispositivo" (
    "id" TEXT NOT NULL,
    "codigo" TEXT NOT NULL,
    "estado" "EstadoCodigoDispositivo" NOT NULL DEFAULT 'PENDIENTE',
    "usuario_id" TEXT,
    "expira_en" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "codigos_dispositivo_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "codigos_dispositivo_codigo_key" ON "codigos_dispositivo"("codigo");

ALTER TABLE "codigos_dispositivo" ADD CONSTRAINT "codigos_dispositivo_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
