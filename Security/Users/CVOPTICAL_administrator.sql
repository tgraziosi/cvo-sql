IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\administrator')
CREATE LOGIN [CVOPTICAL\administrator] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\administrator] FOR LOGIN [CVOPTICAL\administrator]
GO
