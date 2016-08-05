IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\DanielFriedfeld')
CREATE LOGIN [CVOPTICAL\DanielFriedfeld] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\DanielFriedfeld] FOR LOGIN [CVOPTICAL\DanielFriedfeld] WITH DEFAULT_SCHEMA=[CVOPTICAL\DanielFriedfeld]
GO
