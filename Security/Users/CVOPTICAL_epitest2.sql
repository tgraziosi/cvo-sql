IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cvoptical\epitest2')
CREATE LOGIN [cvoptical\epitest2] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\epitest2] FOR LOGIN [cvoptical\epitest2] WITH DEFAULT_SCHEMA=[cvoptical\epitest2]
GO
