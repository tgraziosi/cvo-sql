IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\DQuinlivan')
CREATE LOGIN [CVOPTICAL\DQuinlivan] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\DQuinlivan] FOR LOGIN [CVOPTICAL\DQuinlivan] WITH DEFAULT_SCHEMA=[CVOPTICAL\DQuinlivan]
GO
