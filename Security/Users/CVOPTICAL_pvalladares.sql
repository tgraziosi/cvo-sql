IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\pvalladares')
CREATE LOGIN [CVOPTICAL\pvalladares] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\pvalladares] FOR LOGIN [CVOPTICAL\pvalladares] WITH DEFAULT_SCHEMA=[CVOPTICAL\pvalladares]
GO
