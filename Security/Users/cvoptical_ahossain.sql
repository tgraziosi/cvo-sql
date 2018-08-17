IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ahossain')
CREATE LOGIN [CVOPTICAL\ahossain] FROM WINDOWS
GO
CREATE USER [cvoptical\ahossain] FOR LOGIN [CVOPTICAL\ahossain] WITH DEFAULT_SCHEMA=[CVOPTICAL\ahossain]
GO
