IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lukepaccione')
CREATE LOGIN [CVOPTICAL\lukepaccione] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lukepaccione] FOR LOGIN [CVOPTICAL\lukepaccione] WITH DEFAULT_SCHEMA=[CVOPTICAL\lukepaccione]
GO
