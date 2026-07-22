import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { Request } from 'express';
import { BadRequestException } from '@nestjs/common';

/** Allowed MIME types for profile photos */
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

/** Max file size: 5 MB */
export const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

export const multerProfileOptions = {
  storage: diskStorage({
    destination: './uploads/perfiles',
    filename: (_req: Request, file: Express.Multer.File, cb: (error: Error | null, filename: string) => void) => {
      const ext = extname(file.originalname).toLowerCase();
      const filename = `${uuidv4()}${ext}`;
      cb(null, filename);
    },
  }),
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
  },
  fileFilter: (
    _req: Request,
    file: Express.Multer.File,
    cb: (error: Error | null, acceptFile: boolean) => void,
  ) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new BadRequestException(
          'Tipo de archivo no permitido. Solo se aceptan: jpg, png, webp',
        ),
        false,
      );
    }
  },
};
