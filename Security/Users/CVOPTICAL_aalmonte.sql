IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\aalmonte')
CREATE LOGIN [CVOPTICAL\aalmonte] FROM WINDOWS
GO
