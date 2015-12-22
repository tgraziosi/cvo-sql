SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_copy_user_group_settings_sp]
	@orig_user_name varchar(50),
	@copy_user_name varchar(50)
WITH ENCRYPTION 
AS

DECLARE
	@module   varchar(5),
	@source   varchar(5),
	@function varchar(50),
	@access   int
 
	DECLARE mod_cur
	 CURSOR FOR SELECT module, source 
		      FROM tdc_security_module
		     WHERE userid = @copy_user_name
	OPEN mod_cur
	FETCH NEXT FROM mod_cur INTO @module, @source
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @access = access 
		  FROM tdc_security_module
		 WHERE userid = @orig_user_name
		   AND module = @module
		   AND source = @source

		UPDATE tdc_security_module
		   SET access = @access
		 WHERE userid = @copy_user_name
		   AND module = @module
		   AND source = @source

		FETCH NEXT FROM mod_cur INTO @module, @source
	END
	CLOSE mod_cur
	DEALLOCATE mod_cur


	DECLARE func_cur
	 CURSOR FOR SELECT module, source, [function]
		      FROM tdc_security_function
		     WHERE userid = @copy_user_name
	OPEN func_cur
	FETCH NEXT FROM func_cur INTO @module, @source, @function
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @access = access 
		  FROM tdc_security_function
		 WHERE userid     = @orig_user_name
		   AND module 	  = @module
		   AND source 	  = @source
		   AND [function] = @function

		UPDATE tdc_security_function
		   SET access = @access
		 WHERE userid     = @copy_user_name
		   AND module 	  = @module
		   AND source 	  = @source
		   AND [function] = @function

		FETCH NEXT FROM func_cur INTO @module, @source, @function
	END
	CLOSE func_cur
	DEALLOCATE func_cur


RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_copy_user_group_settings_sp] TO [public]
GO
