IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\maquino')
CREATE LOGIN [CVOPTICAL\maquino] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\maquino] FOR LOGIN [CVOPTICAL\maquino] WITH DEFAULT_SCHEMA=[CVOPTICAL\maquino]
GO