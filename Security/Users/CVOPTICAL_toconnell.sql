IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\toconnell')
CREATE LOGIN [CVOPTICAL\toconnell] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\toconnell] FOR LOGIN [CVOPTICAL\toconnell] WITH DEFAULT_SCHEMA=[CVOPTICAL\toconnell]
GO
