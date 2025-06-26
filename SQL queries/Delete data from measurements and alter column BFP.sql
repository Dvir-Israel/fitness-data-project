--delete data
delete from Measurements;
delete from WeighIns;
--restart counter from one
DBCC CHECKIDENT ('Measurements', RESEED, 0);
DBCC CHECKIDENT ('WeighIns', RESEED, 0);

alter table Measurements
alter column BFP DECIMAL(5,4);