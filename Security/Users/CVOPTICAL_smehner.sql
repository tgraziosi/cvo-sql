IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\smehner')
CREATE LOGIN [CVOPTICAL\smehner] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\smehner] FOR LOGIN [CVOPTICAL\smehner] WITH DEFAULT_SCHEMA=[CVOPTICAL\smehner]
GO
