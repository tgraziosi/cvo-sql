IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\bmcnamee')
CREATE LOGIN [CVOPTICAL\bmcnamee] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\bmcnamee] FOR LOGIN [CVOPTICAL\bmcnamee] WITH DEFAULT_SCHEMA=[CVOPTICAL\bmcnamee]
GO
