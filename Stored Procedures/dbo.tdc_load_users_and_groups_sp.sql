SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_load_users_and_groups_sp]
WITH ENCRYPTION AS
DECLARE @user_id   	VARCHAR(50),
	@admin_val 	INT,
	@group_flag	INT,
	@appuser   	VARCHAR(500),
	@encrypt_buffer VARCHAR(1000),
	@decrypt_buffer VARCHAR(1000),
	@sec_group	VARCHAR(50)

TRUNCATE TABLE #temp_user_sec

DECLARE user_sec_cur
CURSOR FOR
	SELECT [userid], secgroup, group_flag, [appuser]
	  FROM tdc_sec (NOLOCK)          
	 ORDER BY [userid]         

OPEN user_sec_cur
FETCH NEXT FROM user_sec_cur INTO @user_id, @sec_group, @group_flag, @appuser
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @sec_group IS NULL	
		SELECT @encrypt_buffer = 'TRUE ' + @user_id
	ELSE
	BEGIN
		SELECT @encrypt_buffer = 'TRUE ' + @sec_group
		SELECT @appuser = appuser 
		  FROM tdc_sec(NOLOCK)
		 WHERE userid = @sec_group
	END

	EXEC tdc_encrypt @encrypt_buffer, @decrypt_buffer OUTPUT

	IF @decrypt_buffer = @appuser 
		SELECT @admin_val = 1
	ELSE
		SELECT @admin_val = 0
	
	INSERT INTO #temp_user_sec (userid, secgroup, group_flag, admin_val)
	VALUES (@user_id, @sec_group, @group_flag, @admin_val)

	FETCH NEXT FROM user_sec_cur INTO @user_id, @sec_group, @group_flag, @appuser
END

CLOSE user_sec_cur
DEALLOCATE user_sec_cur

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_load_users_and_groups_sp] TO [public]
GO
