IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\eschielke')
CREATE LOGIN [CVOPTICAL\eschielke] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\eschielke] FOR LOGIN [CVOPTICAL\eschielke] WITH DEFAULT_SCHEMA=[CVOPTICAL\eschielke]
GO
