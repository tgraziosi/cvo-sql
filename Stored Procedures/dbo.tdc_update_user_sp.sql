SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_update_user_sp]
@userid		VARCHAR(50),
@newpassword	VARCHAR(1000),
@location	VARCHAR(50),
@language	VARCHAR(50),
@secgroup	VARCHAR(50),
@adminval	INT,
@loguserval     INT,
@mdy_format	varchar(10) = 'MM/DD/YYYY'

WITH ENCRYPTION AS
DECLARE
@password	VARCHAR(1000),
@admin		VARCHAR(1000),
@Buffer 	VARCHAR(1000),
@LogUser        VARCHAR(2)
DECLARE @string VARCHAR(1000)
IF NOT EXISTS(SELECT userid FROM tdc_sec WHERE userid = @userid)
	RAISERROR ('Userid does not exist.', 16,1)

IF ISNULL(@newpassword, '') <> '' 
BEGIN
	EXEC tdc_encrypt @newpassword, @buffer OUTPUT
	SELECT @newpassword = @buffer  
	
	UPDATE tdc_sec SET userpw = @newpassword WHERE userid = @userid
END
if @loguserval = 1
	select @LogUser = 'Y'
else
	select @LogUser = 'N'

IF @adminval = 1
	SELECT @admin = 'TRUE '
ELSE
	SELECT @admin = 'FALSE'
SELECT @admin = @admin + @userid

EXEC tdc_encrypt @admin, @buffer OUTPUT
SELECT @admin = @buffer  

IF ISNULL(@secgroup, '') = ''
	SELECT @secgroup = NULL

UPDATE tdc_sec SET
	location = @location,
	language = @language,
	appuser = @admin,
	secgroup = @secgroup,
	Log_User = @LogUser,
	mdy_format = @mdy_format
	WHERE userid = @userid

IF @adminval = 0 
BEGIN
	UPDATE tdc_security_module 
	   SET access = 0
	 WHERE [userid] = @userid
	   AND module = 'SEC'

	UPDATE tdc_security_function
	   SET access = 0
	 WHERE [userid] = @userid
	   AND (module   = 'SEC'
		    OR ([function] IN('Console','General', 'I.P. / User Configuration',
				     'Pack Out Station','WMS Control', 'Package Control',
				     'Purchasing')	
			AND module = 'CFG'))
END

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_update_user_sp] TO [public]
GO
