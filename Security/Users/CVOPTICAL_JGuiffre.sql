IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\JGuiffre')
CREATE LOGIN [CVOPTICAL\JGuiffre] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\JGuiffre] FOR LOGIN [CVOPTICAL\JGuiffre] WITH DEFAULT_SCHEMA=[CVOPTICAL\JGuiffre]
GO