SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_delete_userid_sp]
		@user_id	VARCHAR(50)
WITH ENCRYPTION
 AS

DECLARE @strMsg	AS VARCHAR(100)
DECLARE @language varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @user_id), 'us_english')

-- SELECT @strMsg = 'Unable to remove User: ' + @user_id
SELECT @strMsg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_delete_userid_sp' AND err_no = -101 AND language = @language
SELECT @strMsg = @strMsg + @user_id

IF @user_id <> 'manager'
	BEGIN
		/****** Only perform ALL of the deletes if each is successful...otherwise ROLLBACK *****/

		BEGIN TRAN
			DELETE FROM tdc_security_function
			WHERE  UserID = @user_id

			DELETE FROM tdc_security_module
				WHERE  UserID = @user_id

			DELETE FROM tdc_sec
				WHERE  UserID = @user_id

			DELETE FROM tdc_user_filter_set
				WHERE  UserID = @user_id

			DELETE FROM tdc_user_config_assign_users	
			 	WHERE userid = @user_id

		COMMIT TRAN

	END

ELSE
	BEGIN
		RAISERROR (@strMsg ,16,1)
	END

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_delete_userid_sp] TO [public]
GO
