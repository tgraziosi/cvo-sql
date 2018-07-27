IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\kennonwilson')
CREATE LOGIN [CVOPTICAL\kennonwilson] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\kennonwilson] FOR LOGIN [CVOPTICAL\kennonwilson] WITH DEFAULT_SCHEMA=[CVOPTICAL\kennonwilson]
GO
