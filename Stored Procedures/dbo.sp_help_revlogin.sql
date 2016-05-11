SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_help_revlogin] @login_name sysname = NULL AS
DECLARE @name    sysname
DECLARE @xstatus int
DECLARE @binpwd  varbinary (256)
DECLARE @txtpwd  sysname
DECLARE @tmpstr  varchar (256)
DECLARE @SID_varbinary varbinary(85)
DECLARE @SID_string varchar(256)

IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR 
--    SELECT sid, name, xstatus, password FROM master..sysxlogins 
    SELECT sid, name, status, password FROM master..syslogins 
      WHERE isntuser=1 AND name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR 
--    SELECT sid, name, xstatus, password FROM master..sysxlogins 
    SELECT sid, name, status, password FROM master..syslogins 
      WHERE isntuser=1 AND name = @login_name
OPEN login_curs 
FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs 
  DEALLOCATE login_curs 
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script ' 
PRINT @tmpstr
SET @tmpstr = '** Generated ' 
  + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
PRINT 'DECLARE @pwd sysname'
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr 
    IF (@xstatus & 4) = 4
    BEGIN -- NT authenticated account/group
      IF (@xstatus & 1) = 1
      BEGIN -- NT login is denied access
        SET @tmpstr = 'EXEC master..sp_denylogin ''' + @name + ''''
        PRINT @tmpstr 
      END
      ELSE BEGIN -- NT login has access
        SET @tmpstr = 'EXEC master..sp_grantlogin ''' + @name + ''''
        PRINT @tmpstr 
      END
    END
    ELSE BEGIN -- SQL Server authentication
      IF (@binpwd IS NOT NULL)
      BEGIN -- Non-null password
        EXEC sp_hexadecimal @binpwd, @txtpwd OUT
        IF (@xstatus & 2048) = 2048
          SET @tmpstr = 'SET @pwd = CONVERT (varchar(256), ' + @txtpwd + ')'
        ELSE
          SET @tmpstr = 'SET @pwd = CONVERT (varbinary(256), ' + @txtpwd + ')'
        PRINT @tmpstr
	EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
        SET @tmpstr = 'EXEC master..sp_addlogin ''' + @name 
          + ''', @pwd, @sid = ' + @SID_string + ', @encryptopt = '
      END
      ELSE BEGIN 
        -- Null password
	EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
        SET @tmpstr = 'EXEC master..sp_addlogin ''' + @name 
          + ''', NULL, @sid = ' + @SID_string + ', @encryptopt = '
      END
      IF (@xstatus & 2048) = 2048
        -- login upgraded from 6.5
        SET @tmpstr = @tmpstr + '''skip_encryption_old''' 
      ELSE 
        SET @tmpstr = @tmpstr + '''skip_encryption'''
      PRINT @tmpstr 
    END
  END
  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd
  END
CLOSE login_curs 
DEALLOCATE login_curs 
RETURN 0
GO