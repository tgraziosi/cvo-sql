IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jmendolia')
CREATE LOGIN [CVOPTICAL\jmendolia] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jmendolia] FOR LOGIN [CVOPTICAL\jmendolia] WITH DEFAULT_SCHEMA=[CVOPTICAL\jmendolia]
GO