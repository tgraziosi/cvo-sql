IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\pgarcia')
CREATE LOGIN [CVOPTICAL\pgarcia] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\pgarcia] FOR LOGIN [CVOPTICAL\pgarcia] WITH DEFAULT_SCHEMA=[CVOPTICAL\pgarcia]
GO
