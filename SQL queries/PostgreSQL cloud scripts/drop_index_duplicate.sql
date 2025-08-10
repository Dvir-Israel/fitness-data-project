-- Schema to inspect
SET search_path TO fitness;
--drop unnecessary index
ALTER TABLE fitness.trainingprogramdetails
  DROP CONSTRAINT IF EXISTS trainingprogramdetails_trainingprogramid_fkey;
