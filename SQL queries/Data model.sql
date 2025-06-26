use [Fitness Database];
-- Users Table
CREATE TABLE Users (
    UserID INT PRIMARY KEY,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Height DECIMAL(5,2)
);

-- Measurements Table
CREATE TABLE Measurements (
    MeasurementID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),
    [Date] DATE,
    Waist DECIMAL(5,2),
    Arm DECIMAL(5,2),
    Neck DECIMAL(5,2),
    Chest DECIMAL(5,2),
    Week INT,
    BFP DECIMAL(5,2)
);

-- Weigh-ins Table
CREATE TABLE WeighIns (
    WeighInID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),
    [Date] DATE,
    WeighIn DECIMAL(5,2),
    Week INT
);

-- Training Programs Table
CREATE TABLE TrainingPrograms (
    TrainingProgramID INT PRIMARY KEY,
    TrainingProgramName NVARCHAR(100)
);

-- Training Program Details Table (junction table with additional attributes)
CREATE TABLE TrainingProgramDetails (
    ExerciseID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),
    TrainingProgramID INT FOREIGN KEY REFERENCES TrainingPrograms(TrainingProgramID),
    [Date] DATE,
    TrainingSplit NVARCHAR(100),
    Exercise NVARCHAR(100),
    [Set] INT,
    Weight DECIMAL(6,2),
    Reps INT
);
