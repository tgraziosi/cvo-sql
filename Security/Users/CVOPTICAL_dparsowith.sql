IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\dparsowith')
CREATE LOGIN [CVOPTICAL\dparsowith] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\dparsowith] FOR LOGIN [CVOPTICAL\dparsowith] WITH DEFAULT_SCHEMA=[CVOPTICAL\dparsowith]
GO