IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cca2')
CREATE LOGIN [cca2] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [cca2] FOR LOGIN [cca2]
GO
