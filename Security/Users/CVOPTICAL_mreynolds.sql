IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mreynolds')
CREATE LOGIN [CVOPTICAL\mreynolds] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mreynolds] FOR LOGIN [CVOPTICAL\mreynolds] WITH DEFAULT_SCHEMA=[CVOPTICAL\mreynolds]
GO
