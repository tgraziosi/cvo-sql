IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\MCrisafulli')
CREATE LOGIN [CVOPTICAL\MCrisafulli] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\MCrisafulli] FOR LOGIN [CVOPTICAL\MCrisafulli] WITH DEFAULT_SCHEMA=[CVOPTICAL\MCrisafulli]
GO
