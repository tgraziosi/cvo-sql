IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cca1')
CREATE LOGIN [cca1] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [cca1] FOR LOGIN [cca1]
GO
