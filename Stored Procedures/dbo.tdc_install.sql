SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_install] 
WITH ENCRYPTION
AS

IF NOT EXISTS (select * from master..syslogins where name = 'tdcsql')
BEGIN
	-- tdcsql does not exist on the server so create it
	--SCR#050887 11/05/08
	EXEC sp_addlogin 'tdcsql', '8700T212D40242c'
END
ELSE
BEGIN
	-- tdcsql already exists: change the password to make sure it is correct
	--SCR#050887 11/05/08
	EXEC sp_password NULL, '8700T212D40242c', 'tdcsql'
END

IF NOT EXISTS (select * from sysusers where name = 'tdcsql')
BEGIN
	-- tdcsql does not exist as a user of the current dB so we make it a dbo
	EXEC sp_adduser @loginame = 'tdcsql', @grpname = 'db_owner'
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_install] TO [public]
GO
