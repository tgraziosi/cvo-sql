IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'unitysvc')
CREATE LOGIN [unitysvc] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [unitysvc] FOR LOGIN [unitysvc] WITH DEFAULT_SCHEMA=[unitysvc]
GO
