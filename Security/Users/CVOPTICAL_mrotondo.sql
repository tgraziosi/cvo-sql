IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mrotondo')
CREATE LOGIN [CVOPTICAL\mrotondo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mrotondo] FOR LOGIN [CVOPTICAL\mrotondo] WITH DEFAULT_SCHEMA=[CVOPTICAL\mrotondo]
GO
