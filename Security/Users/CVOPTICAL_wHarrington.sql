IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\wHarrington')
CREATE LOGIN [CVOPTICAL\wHarrington] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\wHarrington] FOR LOGIN [CVOPTICAL\wHarrington]
GO
