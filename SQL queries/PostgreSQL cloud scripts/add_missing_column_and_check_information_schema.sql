SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'fitness'
  AND table_name = 'trainingprogramdetails'
ORDER BY ordinal_position;

ALTER TABLE fitness.trainingprogramdetails
ADD COLUMN exercise_order smallint NOT NULL DEFAULT 1;
