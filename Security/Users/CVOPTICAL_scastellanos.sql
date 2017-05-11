IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\scastellanos')
CREATE LOGIN [CVOPTICAL\scastellanos] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\scastellanos] FOR LOGIN [CVOPTICAL\scastellanos] WITH DEFAULT_SCHEMA=[CVOPTICAL\scastellanos]
GO
