IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\blax')
CREATE LOGIN [CVOPTICAL\blax] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\blax] FOR LOGIN [CVOPTICAL\blax] WITH DEFAULT_SCHEMA=[CVOPTICAL\blax]
GO