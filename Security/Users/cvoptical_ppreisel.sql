IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cvoptical\ppreisel')
CREATE LOGIN [cvoptical\ppreisel] FROM WINDOWS
GO
CREATE USER [cvoptical\ppreisel] FOR LOGIN [cvoptical\ppreisel] WITH DEFAULT_SCHEMA=[cvoptical\ppreisel]
GO
