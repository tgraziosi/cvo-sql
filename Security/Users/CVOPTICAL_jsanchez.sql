IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jsanchez')
CREATE LOGIN [CVOPTICAL\jsanchez] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jsanchez] FOR LOGIN [CVOPTICAL\jsanchez] WITH DEFAULT_SCHEMA=[CVOPTICAL\jsanchez]
GO