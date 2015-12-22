IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'cvoptical\czea')
CREATE LOGIN [cvoptical\czea] FROM WINDOWS
GO
CREATE USER [cvoptical\czea] FOR LOGIN [cvoptical\czea] WITH DEFAULT_SCHEMA=[cvoptical\czea]
GO
