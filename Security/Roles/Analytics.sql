CREATE ROLE [Analytics]
AUTHORIZATION [dbo]
GO
EXEC sp_addrolemember N'Analytics', N'SDA'
GO
EXEC sp_addrolemember N'Analytics', N'SDA1'
GO
GRANT CREATE DEFAULT TO [Analytics]
GRANT CREATE PROCEDURE TO [Analytics]
GRANT CREATE RULE TO [Analytics]
GRANT CREATE TABLE TO [Analytics]
GRANT CREATE VIEW TO [Analytics]
