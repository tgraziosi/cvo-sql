IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jwatkins')
CREATE LOGIN [CVOPTICAL\jwatkins] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jwatkins] FOR LOGIN [CVOPTICAL\jwatkins] WITH DEFAULT_SCHEMA=[CVOPTICAL\jwatkins]
GO
