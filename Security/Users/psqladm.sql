IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'psqladm')
CREATE LOGIN [psqladm] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [psqladm] FOR LOGIN [psqladm]
GO
