IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\IGarcia')
CREATE LOGIN [CVOPTICAL\IGarcia] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\IGarcia] FOR LOGIN [CVOPTICAL\IGarcia] WITH DEFAULT_SCHEMA=[CVOPTICAL\IGarcia]
GO
