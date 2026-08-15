-- CreateEnum
CREATE TYPE "TipoDispositivo" AS ENUM ('RELOJ', 'TV');

-- AlterTable
ALTER TABLE "codigos_dispositivo" ADD COLUMN     "tipo_dispositivo" "TipoDispositivo" NOT NULL DEFAULT 'RELOJ';

-- AlterTable
ALTER TABLE "tokens_refresco" ADD COLUMN     "tipo_dispositivo" "TipoDispositivo";
