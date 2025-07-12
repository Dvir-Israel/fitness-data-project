use [Fitness Database];
--metrics I want to track:
--WeighIns and Measurements:
--BMI, FFMI, LBM (Lean Body Mass), BFM (Body Fat Mass), W2HR (Waist to height ratio), Body Fat Percentage, Average weight, Average measurement
--Training Program:
--P1RM (Projected 1RM), EVS (Effective Volume Score), ARPW (Average reps per weight), Adjusted Training Load (ATL), WI (Workout intensity)
drop view if exists VW_Base;
drop view if exists VM_Base;
drop view if exists VWM_Base;
drop view if exists VWM_BodyMetrics;
drop view if exists VTP_Base;
drop view if exists VTP_RepAverage;
drop view if exists VTP_TrainingMetrics;
drop view if exists VS_Base;
drop view if exists VS_Scores;
drop view if exists VS_Metrics;
drop view if exists VS_Metrics_Weekly;
GO

create view VW_Base as
	select u.UserID,
		   User_name = u.FirstName + ' ' + u.LastName,
		   w.Week,
		   AverageWeight = avg(w.WeighIn),
		   u.Height
	from WeighIns W
	inner join Users U
	on w.UserID = u.UserID
	group by u.UserID,
			 u.FirstName + ' ' + u.LastName,
			 w.Week,
			 u.Height;

GO

create view VM_Base as
	select u.UserID,
		   User_name = u.FirstName + ' ' + u.LastName,
		   m.Week,
		   AverageChest = avg(m.Chest),
		   AverageWaist = avg(m.Waist),
		   AverageNeck = avg(m.Neck),
		   AverageArm = avg(m.Arm),
		   AverageBFP = avg(m.BFP),
		   u.Height
	from Measurements M
	inner join Users U
	on m.UserID = u.UserID
	group by u.UserID,
			 u.FirstName + ' ' + u.LastName,
			 m.Week,
			 u.Height;

GO

create view VWM_Base as
	select vw.UserID
		   ,vw.User_name
		   ,vw.Week
		   ,vw.AverageWeight
		   ,vw.Height
		   ,vm.AverageChest
		   ,vm.AverageWaist
		   ,vm.AverageNeck
		   ,vm.AverageArm
		   ,vm.AverageBFP
	from VM_Base vm
	inner join VW_Base vw
	on vm.UserID = vw.UserID
	and vm.Week = vw.Week;

GO

create view VWM_BodyMetrics as
	SELECT *,
		   BMI = AverageWeight/(power((Height/100),2)),
		   FFMI = (AverageWeight*(1 - AverageBFP))/(power((Height/100),2)),
		   LBM = AverageWeight*(1 - AverageBFP),
		   BFM = AverageWeight * AverageBFP,
		   W2HR = AverageWaist / Height,
		   Average_Weight_Loss = isnull(AverageWeight - lag(AverageWeight,1) over (partition by UserID order by week),0),
		   Average_Weight_Loss_Pct = isnull((AverageWeight - lag(AverageWeight,1) over (partition by UserID order by week)) / AverageWeight,0)
	from VWM_Base;

GO


create view VTP_Base as
	select u.UserID,
		   User_name = u.FirstName + ' ' + u.LastName,
		   tp.TrainingProgramID,
		   tp.TrainingProgramName,
		   tpd.Date,
		   tpd.TrainingSplit,
		   tpd.Exercise,
		   tpd.[Set],
		   tpd.weight,
		   tpd.reps,
		   tpd.week
	from Users u
	inner join TrainingProgramDetails tpd
	on u.UserID = tpd.UserID
	inner join TrainingPrograms tp
	on tpd.TrainingProgramID = tp.TrainingProgramID;

GO

create view VTP_RepAverage as
	select UserID,
		   User_name,
		   TrainingProgramID,
		   TrainingProgramName,
		   Date,
		   TrainingSplit,
		   Exercise,
		   Weight,
		   Sets = max([Set]),
		   AverageReps = AVG(reps),
		   week
	from VTP_Base
	group by UserID,
		   User_name,
		   TrainingProgramID,
		   TrainingProgramName,
		   Date,
		   TrainingSplit,
		   Exercise,
		   Weight,
		   week;

GO
create view VTP_TrainingMetrics as
    with cteMetrics as
	(select vtpra.*,
		   vwmb.AverageWeight,
		   P1RM = case when AverageReps > 15 and Weight = 0 then (vwmb.AverageWeight / (dbo.Calculate1RMPercentage(15) - (cast(AverageReps as int) - 15) * 0.025)) - vwmb.AverageWeight
				  when AverageReps > 15 then Weight / (dbo.Calculate1RMPercentage(15) - (cast(AverageReps as int) - 15) * 0.025)
				  when Weight = 0 then (vwmb.AverageWeight / dbo.Calculate1RMPercentage(cast(AverageReps as int))) - vwmb.AverageWeight
				  else Weight / dbo.Calculate1RMPercentage(cast(AverageReps as int)) end,
		   EVS = case when AverageReps > 15 and Weight = 0 then 1 * AverageReps * [Sets] * (dbo.Calculate1RMPercentage(15) - (cast(AverageReps as int) - 15) * 0.025)
					  when AverageReps > 15 then Weight * AverageReps * [Sets] * (dbo.Calculate1RMPercentage(15) - (cast(AverageReps as int) - 15) * 0.025)
					  when Weight = 0 then 1 * AverageReps * [Sets] * dbo.Calculate1RMPercentage(cast(AverageReps as int))
					  else Weight * AverageReps * [Sets] * dbo.Calculate1RMPercentage(cast(AverageReps as int)) end,
		   ATL = case when Weight = 0 then 1.0 / AverageReps
		              else Weight / AverageReps end
	from VTP_RepAverage vtpra
	inner join VWM_Base vwmb
	on vtpra.UserID = vwmb.UserID
	and vtpra.Week = vwmb.Week)
	select *,
	       WI = EVS * ATL
	from cteMetrics;

GO

create view VS_Base as
	select u.UserID,
		   User_name = u.FirstName + ' ' + u.LastName,
		   sd.CalendarDate,
		   sd.SleepStartTimestampGMT,
		   sd.SleepEndTimestampGMT,
		   sd.LowestRespiration,
		   sd.HighestRespiration,
		   sd.AverageRespiration,
		   sd.AwakeSleepSeconds,
		   sd.DeepSleepSeconds,
		   sd.LightSleepSeconds,
		   isnull(sd.RemSleepSeconds,0) as RemSleepSeconds,
		   (sd.AwakeSleepSeconds + sd.DeepSleepSeconds + sd.LightSleepSeconds + isnull(sd.RemSleepSeconds,0)) /3600.0 as total_sleep_time_hours  
	from Users u
	inner join SleepData sd
	on u.UserID = sd.UserID;

GO

create view VS_Scores as
SELECT *,
    -- Total Sleep Score
    CASE 
        WHEN total_sleep_time_hours < 5 THEN 2
        WHEN total_sleep_time_hours < 6 THEN 4
        WHEN total_sleep_time_hours < 7 THEN 6
        WHEN total_sleep_time_hours <= 8.5 THEN 10
        WHEN total_sleep_time_hours <= 9.5 THEN 8
        ELSE 6
    END AS TotalSleepScore,

    -- REM Sleep Score
    CASE 
        WHEN REM_ratio < 0.05 THEN 2
        WHEN REM_ratio < 0.10 THEN 4
        WHEN REM_ratio < 0.15 THEN 6
        WHEN REM_ratio < 0.20 THEN 8
        WHEN REM_ratio BETWEEN 0.26 AND 0.30 THEN 8
        WHEN REM_ratio BETWEEN 0.31 AND 0.35 THEN 6
        WHEN REM_ratio BETWEEN 0.36 AND 0.40 THEN 4
        WHEN REM_ratio > 0.40 THEN 2
        ELSE 10
    END AS REMSleepScore,

    -- Deep Sleep Score
    CASE 
        WHEN Deep_ratio < 0.04 THEN 2
        WHEN Deep_ratio BETWEEN 0.04 AND 0.06 THEN 4
        WHEN Deep_ratio BETWEEN 0.07 AND 0.09 THEN 6
        WHEN Deep_ratio BETWEEN 0.10 AND 0.12 THEN 8
        WHEN Deep_ratio BETWEEN 0.24 AND 0.29 THEN 8
        WHEN Deep_ratio BETWEEN 0.30 AND 0.34 THEN 6
        WHEN Deep_ratio BETWEEN 0.35 AND 0.39 THEN 4
        WHEN Deep_ratio > 0.40 THEN 2
        ELSE 10
    END AS DeepSleepScore,

    -- Light Sleep Score
    CASE 
        WHEN Light_ratio < 0.35 OR Light_ratio > 0.65 THEN 5
        ELSE 10
    END AS LightSleepScore,
	CASE 
		WHEN Awake_ratio <= 0.10 THEN 10
		WHEN Awake_ratio <= 0.15 THEN 9
		WHEN Awake_ratio <= 0.20 THEN 8
		WHEN Awake_ratio <= 0.25 THEN 7
		WHEN Awake_ratio <= 0.30 THEN 6
		WHEN Awake_ratio <= 0.35 THEN 5
		WHEN Awake_ratio <= 0.40 THEN 4
		WHEN Awake_ratio <= 0.45 THEN 3
		WHEN Awake_ratio <= 0.50 THEN 2
		ELSE 1
	END AS AwakeSleepScore,
	CASE 
	  WHEN HighestRespiration - LowestRespiration <= 4 THEN 10
	  WHEN HighestRespiration - LowestRespiration <= 6 THEN 8
	  WHEN HighestRespiration - LowestRespiration <= 8 THEN 6
	  ELSE 3
    END AS RespirationScore
FROM (
    SELECT *,
        -- Precompute stage ratios
        CAST(RemSleepSeconds AS FLOAT) / (3600 * total_sleep_time_hours) AS REM_ratio,
        CAST(DeepSleepSeconds AS FLOAT) / (3600 * total_sleep_time_hours) AS Deep_ratio,
        CAST(LightSleepSeconds AS FLOAT) / (3600 * total_sleep_time_hours) AS Light_ratio,
		CAST(AwakeSleepSeconds AS FLOAT) / (3600 * total_sleep_time_hours) AS Awake_ratio
    FROM VS_Base
) AS base;

GO
create view VS_Metrics as
	with cte_stage_score as
	(select *,
			(REMSleepScore + DeepSleepScore + LightSleepScore + AwakeSleepScore) / 4.0 AS StageScore
	from VS_Scores),
	cte_overall_score as
	(select *,
		   TotalSleepScore * 3 + StageScore * 4 + RespirationScore * 3 AS OverallSleepScore
	from cte_stage_score)
	select *,
		   CASE 
				WHEN OverallSleepScore >= 85 THEN 'Excellent'
				WHEN OverallSleepScore >= 70 THEN 'Good'
				WHEN OverallSleepScore >= 55 THEN 'Decent'
				WHEN OverallSleepScore >= 40 THEN 'Poor'
				ELSE 'Very Poor'
		   END AS SleepQualityRating
	from cte_overall_score;

GO

create view VS_Metrics_Weekly as
select w.UserID,
       vsm.User_name,
	   w.Week,
	   AVG(vsm.OverallSleepScore) as AvgSleepScore,
	   CASE 
				WHEN AVG(vsm.OverallSleepScore) >= 85 THEN 'Excellent'
				WHEN AVG(vsm.OverallSleepScore) >= 70 THEN 'Good'
				WHEN AVG(vsm.OverallSleepScore) >= 55 THEN 'Decent'
				WHEN AVG(vsm.OverallSleepScore) >= 40 THEN 'Poor'
				ELSE 'Very Poor'
		   END AS SleepQualityRating
from VS_Metrics vsm
inner join WeighIns w
on vsm.UserID = w.UserID
and vsm.CalendarDate = w.Date
group by w.UserID,
       vsm.User_name,
	   w.Week;

GO

select *
from VTP_TrainingMetrics;

select *
from VWM_BodyMetrics;

select *
from VS_Metrics;

select *
from VS_Metrics_Weekly;


