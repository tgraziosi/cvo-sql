IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\kgurciullo')
CREATE LOGIN [CVOPTICAL\kgurciullo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\kgurciullo] FOR LOGIN [CVOPTICAL\kgurciullo] WITH DEFAULT_SCHEMA=[CVOPTICAL\kgurciullo]
GO