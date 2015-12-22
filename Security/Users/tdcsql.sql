IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'tdcsql')
CREATE LOGIN [tdcsql] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [tdcsql] FOR LOGIN [tdcsql] WITH DEFAULT_SCHEMA=[tdcsql]
GO
