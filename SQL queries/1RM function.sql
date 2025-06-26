CREATE FUNCTION dbo.Calculate1RMPercentage (@Reps INT)
RETURNS DECIMAL(5,4)
AS
BEGIN
    DECLARE @Percentage DECIMAL(5,4);
    
    -- Set the percentage based on the number of reps
    IF @Reps = 1
        SET @Percentage = 1.0000;   -- 100% of 1RM
    ELSE IF @Reps = 2
        SET @Percentage = 0.9500;   -- 95% of 1RM
    ELSE IF @Reps = 3
        SET @Percentage = 0.9300;   -- 93% of 1RM
    ELSE IF @Reps = 4
        SET @Percentage = 0.9000;   -- 90% of 1RM
    ELSE IF @Reps = 5
        SET @Percentage = 0.8700;   -- 87% of 1RM
    ELSE IF @Reps = 6
        SET @Percentage = 0.8500;   -- 85% of 1RM
    ELSE IF @Reps = 7
        SET @Percentage = 0.8300;   -- 83% of 1RM
    ELSE IF @Reps = 8
        SET @Percentage = 0.8000;   -- 80% of 1RM
    ELSE IF @Reps = 9
        SET @Percentage = 0.7700;   -- 77% of 1RM
    ELSE IF @Reps = 10
        SET @Percentage = 0.7500;   -- 75% of 1RM
    ELSE IF @Reps = 11
        SET @Percentage = 0.7300;   -- 73% of 1RM
    ELSE IF @Reps = 12
        SET @Percentage = 0.7000;   -- 70% of 1RM
    ELSE IF @Reps = 13
        SET @Percentage = 0.6800;   -- 68% of 1RM
    ELSE IF @Reps = 14
        SET @Percentage = 0.6500;   -- 65% of 1RM
    ELSE IF @Reps = 15
        SET @Percentage = 0.6300;   -- 63% of 1RM
    ELSE
        SET @Percentage = NULL;     -- If reps are out of range

    RETURN @Percentage;
END;
