IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\cgiammanco')
CREATE LOGIN [CVOPTICAL\cgiammanco] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\cgiammanco] FOR LOGIN [CVOPTICAL\cgiammanco] WITH DEFAULT_SCHEMA=[CVOPTICAL\cgiammanco]
GO
