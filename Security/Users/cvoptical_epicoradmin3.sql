IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cvoptical\epicoradmin3')
CREATE LOGIN [cvoptical\epicoradmin3] FROM WINDOWS
GO
CREATE USER [cvoptical\epicoradmin3] FOR LOGIN [cvoptical\epicoradmin3] WITH DEFAULT_SCHEMA=[cvoptical\epicoradmin3]
GO
