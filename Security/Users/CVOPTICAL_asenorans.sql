IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\asenorans')
CREATE LOGIN [CVOPTICAL\asenorans] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\asenorans] FOR LOGIN [CVOPTICAL\asenorans] WITH DEFAULT_SCHEMA=[CVOPTICAL\asenorans]
GO
