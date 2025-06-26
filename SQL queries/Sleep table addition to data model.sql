use [Fitness Database];
-- Sleep Data Table
CREATE TABLE SleepData (
    SleepID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT FOREIGN KEY REFERENCES Users(UserID),

    CalendarDate DATE,
    SleepStartTimestampGMT DATETIME,
    SleepEndTimestampGMT DATETIME,

    AwakeSleepSeconds INT,
    DeepSleepSeconds INT,
    LightSleepSeconds INT,
    RemSleepSeconds INT,
    UnmeasurableSeconds INT,

    AverageRespiration DECIMAL(5,2),
    HighestRespiration DECIMAL(5,2),
    LowestRespiration DECIMAL(5,2),

    Retro BIT,
    SleepWindowConfirmationType VARCHAR(50) -- or adjust depending on expected content
);

alter table SleepData
alter column SleepWindowConfirmationType NVARCHAR(50);
