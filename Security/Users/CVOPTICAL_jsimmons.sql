IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jsimmons')
CREATE LOGIN [CVOPTICAL\jsimmons] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jsimmons] FOR LOGIN [CVOPTICAL\jsimmons] WITH DEFAULT_SCHEMA=[CVOPTICAL\jsimmons]
GO
