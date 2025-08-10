-- Idempotent constraints script for schema: fitness
SET search_path TO fitness;

---------------------------------------
-- 1) DROP existing FOREIGN KEYS (safe)
---------------------------------------
ALTER TABLE Measurements
  DROP CONSTRAINT IF EXISTS measurements_userid_fkey;

ALTER TABLE WeighIns
  DROP CONSTRAINT IF EXISTS weighins_userid_fkey;

ALTER TABLE TrainingProgramDetails
  DROP CONSTRAINT IF EXISTS trainingprogramdetails_userid_fkey,
  DROP CONSTRAINT IF EXISTS trainingprogramdetails_tpid_fkey;

ALTER TABLE SleepData
  DROP CONSTRAINT IF EXISTS sleepdata_userid_fkey;

---------------------------------------
-- 2) DROP existing CHECK constraints (safe)
---------------------------------------
ALTER TABLE Measurements
  DROP CONSTRAINT IF EXISTS chk_measure_waist_nonneg,
  DROP CONSTRAINT IF EXISTS chk_measure_arm_nonneg,
  DROP CONSTRAINT IF EXISTS chk_measure_neck_nonneg,
  DROP CONSTRAINT IF EXISTS chk_measure_chest_nonneg,
  DROP CONSTRAINT IF EXISTS chk_measure_week_range,
  DROP CONSTRAINT IF EXISTS chk_measure_week_process,
  DROP CONSTRAINT IF EXISTS chk_measure_bfp_range;

ALTER TABLE WeighIns
  DROP CONSTRAINT IF EXISTS chk_weighin_nonneg,
  DROP CONSTRAINT IF EXISTS chk_weighin_week,
  DROP CONSTRAINT IF EXISTS chk_weighin_week_process;

ALTER TABLE TrainingProgramDetails
  DROP CONSTRAINT IF EXISTS chk_tpd_set_pos,
  DROP CONSTRAINT IF EXISTS chk_tpd_reps_nonneg,
  DROP CONSTRAINT IF EXISTS chk_tpd_reptarget_pos,
  DROP CONSTRAINT IF EXISTS chk_tpd_weight_nonneg,
  DROP CONSTRAINT IF EXISTS chk_tpd_week_range,
  DROP CONSTRAINT IF EXISTS chk_tpd_week_process,
  DROP CONSTRAINT IF EXISTS chk_tpd_rpe_range,
  DROP CONSTRAINT IF EXISTS chk_tpd_exercisetype;

ALTER TABLE SleepData
  DROP CONSTRAINT IF EXISTS chk_sleep_nonneg,
  DROP CONSTRAINT IF EXISTS chk_sleep_resp_nonneg,
  DROP CONSTRAINT IF EXISTS chk_sleep_time_order;

---------------------------------------
-- 3) RE-ADD FOREIGN KEYS
---------------------------------------
-- If a user is deleted, cascade their personal logs
ALTER TABLE Measurements
  ADD CONSTRAINT measurements_userid_fkey
  FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE;

ALTER TABLE WeighIns
  ADD CONSTRAINT weighins_userid_fkey
  FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE;

ALTER TABLE TrainingProgramDetails
  ADD CONSTRAINT trainingprogramdetails_userid_fkey
  FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE;

-- Prevent accidental deletion of a program that has details
ALTER TABLE TrainingProgramDetails
  ADD CONSTRAINT trainingprogramdetails_tpid_fkey
  FOREIGN KEY (TrainingProgramID) REFERENCES TrainingPrograms(TrainingProgramID) ON DELETE RESTRICT;

ALTER TABLE SleepData
  ADD CONSTRAINT sleepdata_userid_fkey
  FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE;

---------------------------------------
-- 4) NOT NULLs (practical)
---------------------------------------
ALTER TABLE Measurements
  ALTER COLUMN UserID SET NOT NULL,
  ALTER COLUMN Date   SET NOT NULL;

ALTER TABLE WeighIns
  ALTER COLUMN UserID SET NOT NULL,
  ALTER COLUMN Date   SET NOT NULL;

ALTER TABLE TrainingPrograms
  ALTER COLUMN TrainingProgramName SET NOT NULL;

ALTER TABLE TrainingProgramDetails
  ALTER COLUMN UserID SET NOT NULL,
  ALTER COLUMN TrainingProgramID SET NOT NULL,
  ALTER COLUMN Date SET NOT NULL,
  ALTER COLUMN Exercise SET NOT NULL,
  ALTER COLUMN set SET NOT NULL;

ALTER TABLE SleepData
  ALTER COLUMN UserID SET NOT NULL,
  ALTER COLUMN CalendarDate SET NOT NULL;

---------------------------------------
-- 5) CHECK constraints (realistic)
---------------------------------------
-- Measurements: non-negatives, process week >= 1, BFP 0..100
ALTER TABLE Measurements
  ADD CONSTRAINT chk_measure_waist_nonneg  CHECK (Waist IS NULL OR Waist >= 0),
  ADD CONSTRAINT chk_measure_arm_nonneg    CHECK (Arm   IS NULL OR Arm   >= 0),
  ADD CONSTRAINT chk_measure_neck_nonneg   CHECK (Neck  IS NULL OR Neck  >= 0),
  ADD CONSTRAINT chk_measure_chest_nonneg  CHECK (Chest IS NULL OR Chest >= 0),
  ADD CONSTRAINT chk_measure_week_process  CHECK (week IS NULL OR week >= 1),
  ADD CONSTRAINT chk_measure_bfp_range     CHECK (BFP  IS NULL OR (BFP >= 0 AND BFP <= 100));

-- Weigh-ins: non-negative, process week >= 1
ALTER TABLE WeighIns
  ADD CONSTRAINT chk_weighin_nonneg CHECK (WeighIn IS NULL OR WeighIn >= 0),
  ADD CONSTRAINT chk_weighin_week_process CHECK (week IS NULL OR week >= 1);

-- TrainingProgramDetails: set>0, Reps>=0, targets>0, weight>=0, week>=1, RPE 1..10, exercise type optional whitelist
ALTER TABLE TrainingProgramDetails
  ADD CONSTRAINT chk_tpd_set_pos        CHECK (set > 0),
  ADD CONSTRAINT chk_tpd_reps_nonneg    CHECK (Reps IS NULL OR Reps >= 0),
  ADD CONSTRAINT chk_tpd_reptarget_pos  CHECK (RepTarget IS NULL OR RepTarget > 0),
  ADD CONSTRAINT chk_tpd_weight_nonneg  CHECK (Weight IS NULL OR Weight >= 0),
  ADD CONSTRAINT chk_tpd_week_process   CHECK (week IS NULL OR week >= 1),
  ADD CONSTRAINT chk_tpd_rpe_range      CHECK (RPE IS NULL OR RPE BETWEEN 1 AND 10),
  ADD CONSTRAINT chk_tpd_exercisetype   CHECK (ExerciseType IS NULL OR ExerciseType IN
      ('compound','isolation','cardio','accessory','mobility'));

-- SleepData: non-negatives, respiration non-negatives, end > start when both present
ALTER TABLE SleepData
  ADD CONSTRAINT chk_sleep_nonneg CHECK (
    (AwakeSleepSeconds   IS NULL OR AwakeSleepSeconds   >= 0) AND
    (DeepSleepSeconds    IS NULL OR DeepSleepSeconds    >= 0) AND
    (LightSleepSeconds   IS NULL OR LightSleepSeconds   >= 0) AND
    (RemSleepSeconds     IS NULL OR RemSleepSeconds     >= 0) AND
    (UnmeasurableSeconds IS NULL OR UnmeasurableSeconds >= 0)
  ),
  ADD CONSTRAINT chk_sleep_resp_nonneg CHECK (
    (AverageRespiration IS NULL OR AverageRespiration >= 0) AND
    (HighestRespiration IS NULL OR HighestRespiration >= 0) AND
    (LowestRespiration  IS NULL OR LowestRespiration  >= 0)
  ),
  ADD CONSTRAINT chk_sleep_time_order CHECK (
    SleepStartTimestampGMT IS NULL OR
    SleepEndTimestampGMT   IS NULL OR
    SleepEndTimestampGMT   >  SleepStartTimestampGMT
  );
