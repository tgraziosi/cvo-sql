IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\smembreno')
CREATE LOGIN [CVOPTICAL\smembreno] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\smembreno] FOR LOGIN [CVOPTICAL\smembreno] WITH DEFAULT_SCHEMA=[CVOPTICAL\smembreno]
GO