IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\GTaveras')
CREATE LOGIN [CVOPTICAL\GTaveras] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\GTaveras] FOR LOGIN [CVOPTICAL\GTaveras] WITH DEFAULT_SCHEMA=[CVOPTICAL\GTaveras]
GO
