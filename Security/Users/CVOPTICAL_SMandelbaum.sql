IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\SMandelbaum')
CREATE LOGIN [CVOPTICAL\SMandelbaum] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\SMandelbaum] FOR LOGIN [CVOPTICAL\SMandelbaum] WITH DEFAULT_SCHEMA=[CVOPTICAL\SMandelbaum]
GO