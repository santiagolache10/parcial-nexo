-- Compatibilidad de estados para el flujo de proyecto final en PostgreSQL.
-- Elimina únicamente restricciones CHECK de la tabla anteproyectos que dependan de la columna estado.
-- No borra registros ni modifica las calificaciones.
DO $nexo$
DECLARE restr RECORD;
BEGIN
  FOR restr IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'parcial_julian'
      AND rel.relname = 'anteproyectos'
      AND con.contype = 'c'
      AND pg_get_constraintdef(con.oid) ILIKE '%estado%'
  LOOP
    EXECUTE format('ALTER TABLE parcial_julian.anteproyectos DROP CONSTRAINT %I', restr.conname);
  END LOOP;
END
$nexo$;

ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS etapa_actual VARCHAR(35) NOT NULL DEFAULT 'ANTEPROYECTO';
ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS proyecto_final_url VARCHAR(900);
ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS calificacion_final NUMERIC(3,2);
ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS version_final INTEGER NOT NULL DEFAULT 1;
ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS fecha_director TIMESTAMP;
ALTER TABLE parcial_julian.anteproyectos ADD COLUMN IF NOT EXISTS fecha_evaluador TIMESTAMP;
ALTER TABLE parcial_julian.revisiones ADD COLUMN IF NOT EXISTS etapa VARCHAR(35) NOT NULL DEFAULT 'ANTEPROYECTO';
