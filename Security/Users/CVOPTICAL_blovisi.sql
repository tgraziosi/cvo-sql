IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\blovisi')
CREATE LOGIN [CVOPTICAL\blovisi] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\blovisi] FOR LOGIN [CVOPTICAL\blovisi] WITH DEFAULT_SCHEMA=[CVOPTICAL\blovisi]
GO
