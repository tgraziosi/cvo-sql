IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ebennett')
CREATE LOGIN [CVOPTICAL\ebennett] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ebennett] FOR LOGIN [CVOPTICAL\ebennett] WITH DEFAULT_SCHEMA=[CVOPTICAL\ebennett]
GO