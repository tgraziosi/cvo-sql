IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\kumanzor')
CREATE LOGIN [CVOPTICAL\kumanzor] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\kumanzor] FOR LOGIN [CVOPTICAL\kumanzor] WITH DEFAULT_SCHEMA=[CVOPTICAL\kumanzor]
GO
