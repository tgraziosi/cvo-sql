IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\NUmanzor')
CREATE LOGIN [CVOPTICAL\NUmanzor] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\NUmanzor] FOR LOGIN [CVOPTICAL\NUmanzor] WITH DEFAULT_SCHEMA=[CVOPTICAL\NUmanzor]
GO