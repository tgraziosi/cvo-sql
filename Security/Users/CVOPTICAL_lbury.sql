IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lbury')
CREATE LOGIN [CVOPTICAL\lbury] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lbury] FOR LOGIN [CVOPTICAL\lbury] WITH DEFAULT_SCHEMA=[CVOPTICAL\lbury]
GO
