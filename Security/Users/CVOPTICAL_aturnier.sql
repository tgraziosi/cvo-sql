IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\aturnier')
CREATE LOGIN [CVOPTICAL\aturnier] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\aturnier] FOR LOGIN [CVOPTICAL\aturnier] WITH DEFAULT_SCHEMA=[CVOPTICAL\aturnier]
GO
