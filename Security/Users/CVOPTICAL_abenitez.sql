IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\abenitez')
CREATE LOGIN [CVOPTICAL\abenitez] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\abenitez] FOR LOGIN [CVOPTICAL\abenitez]
GO