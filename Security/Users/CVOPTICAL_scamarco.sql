IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\scamarco')
CREATE LOGIN [CVOPTICAL\scamarco] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\scamarco] FOR LOGIN [CVOPTICAL\scamarco] WITH DEFAULT_SCHEMA=[CVOPTICAL\scamarco]
GO