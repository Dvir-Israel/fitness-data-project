-- note from dvir - this script will not work if you're running it as a bulk - run each table seperately - thanks postgresql :)

-- Create schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS fitness;

-- USERS
CREATE TABLE fitness.Users (
    UserID SERIAL PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Height NUMERIC(5,2)
);

-- MEASUREMENTS
CREATE TABLE fitness.Measurements (
    MeasurementID SERIAL PRIMARY KEY,
    UserID INT REFERENCES fitness.Users(UserID),
    Date DATE,
    Waist NUMERIC(5,2),
    Arm NUMERIC(5,2),
    Neck NUMERIC(5,2),
    Chest NUMERIC(5,2),
    Week INT,
    BFP NUMERIC
);
-- run the first two table together with the run schema and then run those below seperately because postre is stupid
-- WEIGH-INS
CREATE TABLE fitness.WeighIns (
    WeighInID SERIAL PRIMARY KEY,
    UserID INT REFERENCES fitness.Users(UserID),
    Date DATE,
    WeighIn NUMERIC(5,2),
    Week INT
);

-- TRAINING PROGRAMS
CREATE TABLE fitness.TrainingPrograms (
    TrainingProgramID SERIAL PRIMARY KEY,
    TrainingProgramName VARCHAR(100)
);

-- TRAINING PROGRAM DETAILS (UPGRADED)
CREATE TABLE fitness.TrainingProgramDetails (
    ExerciseID SERIAL PRIMARY KEY,
    UserID INT REFERENCES fitness.Users(UserID),
    TrainingProgramID INT REFERENCES fitness.TrainingPrograms(TrainingProgramID),
    Date DATE,
    TrainingSplit VARCHAR(100),
    Exercise VARCHAR(100),
    Set INT,
    Weight NUMERIC(6,2),
    Reps INT,
    RepTarget INT,
    Week INT,
    ExerciseType VARCHAR(50),
    RPE SMALLINT,
    RestPeriodSeconds INT,
    Comments TEXT
);

-- SLEEP DATA
CREATE TABLE fitness.SleepData (
    SleepID SERIAL PRIMARY KEY,
    UserID INT REFERENCES fitness.Users(UserID),
    CalendarDate DATE,
    SleepStartTimestampGMT TIMESTAMP,
    SleepEndTimestampGMT TIMESTAMP,
    AwakeSleepSeconds INT,
    DeepSleepSeconds INT,
    LightSleepSeconds INT,
    RemSleepSeconds INT,
    UnmeasurableSeconds INT,
    AverageRespiration NUMERIC(5,2),
    HighestRespiration NUMERIC(5,2),
    LowestRespiration NUMERIC(5,2),
    Retro BOOLEAN,
    SleepWindowConfirmationType VARCHAR(50)
);

-- Consider adding exercises table and for each training program, add constraints for what type of muscle groups will be included in each split