IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\alandstrom')
CREATE LOGIN [CVOPTICAL\alandstrom] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\alandstrom] FOR LOGIN [CVOPTICAL\alandstrom] WITH DEFAULT_SCHEMA=[CVOPTICAL\alandstrom]
GO