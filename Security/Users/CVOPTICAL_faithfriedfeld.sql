IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\faithfriedfeld')
CREATE LOGIN [CVOPTICAL\faithfriedfeld] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\faithfriedfeld] FOR LOGIN [CVOPTICAL\faithfriedfeld] WITH DEFAULT_SCHEMA=[CVOPTICAL\faithfriedfeld]
GO
