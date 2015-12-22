IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lucasfriedfeld')
CREATE LOGIN [CVOPTICAL\lucasfriedfeld] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lucasfriedfeld] FOR LOGIN [CVOPTICAL\lucasfriedfeld] WITH DEFAULT_SCHEMA=[CVOPTICAL\lucasfriedfeld]
GO
