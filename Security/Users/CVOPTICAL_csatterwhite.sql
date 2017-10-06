IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\csatterwhite')
CREATE LOGIN [CVOPTICAL\csatterwhite] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\csatterwhite] FOR LOGIN [CVOPTICAL\csatterwhite] WITH DEFAULT_SCHEMA=[CVOPTICAL\csatterwhite]
GO
