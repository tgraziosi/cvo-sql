IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'emktg')
CREATE LOGIN [emktg] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [emktg] FOR LOGIN [emktg]
GO
