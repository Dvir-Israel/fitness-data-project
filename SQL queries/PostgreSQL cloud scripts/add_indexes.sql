SET search_path TO fitness;

-- MEASUREMENTS
CREATE INDEX IF NOT EXISTS idx_measurements_userid ON measurements(userid);
CREATE INDEX IF NOT EXISTS idx_measurements_date   ON measurements(date);
CREATE INDEX IF NOT EXISTS idx_measurements_week   ON measurements(week);
-- Optional if you often filter by both:
-- CREATE INDEX IF NOT EXISTS idx_measurements_user_date ON measurements(userid, date);

-- WEIGHINS
CREATE INDEX IF NOT EXISTS idx_weighins_userid ON weighins(userid);
CREATE INDEX IF NOT EXISTS idx_weighins_date   ON weighins(date);
CREATE INDEX IF NOT EXISTS idx_weighins_week   ON weighins(week);
-- Optional composite:
-- CREATE INDEX IF NOT EXISTS idx_weighins_user_date ON weighins(userid, date);

-- TRAINING PROGRAM DETAILS
CREATE INDEX IF NOT EXISTS idx_tpd_userid ON trainingprogramdetails(userid);
CREATE INDEX IF NOT EXISTS idx_tpd_tpid   ON trainingprogramdetails(trainingprogramid);
CREATE INDEX IF NOT EXISTS idx_tpd_date   ON trainingprogramdetails(date);
CREATE INDEX IF NOT EXISTS idx_tpd_week   ON trainingprogramdetails(week);
-- Optional composites:
-- CREATE INDEX IF NOT EXISTS idx_tpd_user_date ON trainingprogramdetails(userid, date);
-- CREATE INDEX IF NOT EXISTS idx_tpd_tpid_date ON trainingprogramdetails(trainingprogramid, date);

-- SLEEP DATA
CREATE INDEX IF NOT EXISTS idx_sleep_userid ON sleepdata(userid);
CREATE INDEX IF NOT EXISTS idx_sleep_date   ON sleepdata(calendardate);

-- TRAINING PROGRAMS (usually small; skip unless needed)
-- CREATE INDEX IF NOT EXISTS idx_tprograms_name ON trainingprograms(trainingprogramname);
