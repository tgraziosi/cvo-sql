IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ADivitashvili')
CREATE LOGIN [CVOPTICAL\ADivitashvili] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ADivitashvili] FOR LOGIN [CVOPTICAL\ADivitashvili]
GO
