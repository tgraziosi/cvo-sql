IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mvelasquez')
CREATE LOGIN [CVOPTICAL\mvelasquez] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mvelasquez] FOR LOGIN [CVOPTICAL\mvelasquez] WITH DEFAULT_SCHEMA=[CVOPTICAL\mvelasquez]
GO