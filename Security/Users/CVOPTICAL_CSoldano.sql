IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\CSoldano')
CREATE LOGIN [CVOPTICAL\CSoldano] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\CSoldano] FOR LOGIN [CVOPTICAL\CSoldano] WITH DEFAULT_SCHEMA=[CVOPTICAL\CSoldano]
GO