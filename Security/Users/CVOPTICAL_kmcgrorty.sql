IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\kmcgrorty')
CREATE LOGIN [CVOPTICAL\kmcgrorty] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\kmcgrorty] FOR LOGIN [CVOPTICAL\kmcgrorty] WITH DEFAULT_SCHEMA=[CVOPTICAL\kmcgrorty]
GO
