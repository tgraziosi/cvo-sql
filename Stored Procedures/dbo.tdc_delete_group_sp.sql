SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_delete_group_sp]
		@GroupName	VARCHAR(50),
		@bDeleteMembers int = 0
WITH ENCRYPTION
 AS

DECLARE @strMsg	varchar (100)
DECLARE @TempID varchar (25)

--##########################################################################################################################3
-- If Users aren't being removed, set their security
--##########################################################################################################################3

		/****** Only perform ALL of the deletes if each is successful...otherwise ROLLBACK *****/

		BEGIN TRAN

--##########################################################################################################################3
-- Remove Group
--##########################################################################################################################3



				DELETE FROM tdc_security_function
					WHERE  userid = @GroupName
		IF @@ERROR = 0
			BEGIN
				DELETE FROM tdc_security_module
					WHERE  userid = @GroupName
			END
		IF @@ERROR = 0 
			BEGIN
				DELETE FROM tdc_sec 
					WHERE userid = @GroupName
			END
--##########################################################################################################################3
-- Remove all users of that group
--##########################################################################################################################3
IF @bDeleteMembers = 0 
   BEGIN
	UPDATE tdc_sec SET SecGroup = NULL WHERE SecGroup = @GroupName
   END
ELSE
   BEGIN
	IF @@ERROR = 0
	BEGIN
		DECLARE Sec_Cursor INSENSITIVE CURSOR FOR
		 SELECT UserID FROM tdc_sec (NOLOCK)
		  WHERE SecGroup = @GroupName

		OPEN Sec_Cursor

		FETCH NEXT FROM Sec_Cursor 
			INTO @TempID

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			EXEC tdc_delete_userid_sp @TempID
			FETCH NEXT FROM Sec_Cursor 
			INTO @TempID
		END

		CLOSE Sec_Cursor
		DEALLOCATE Sec_Cursor
	END
END
	
	--If no error, committran
	IF @@ERROR = 0
		BEGIN
			COMMIT TRAN
		END
	ELSE
		BEGIN
			ROLLBACK TRAN
			RAISERROR (@strMsg ,16,1)

		END

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_delete_group_sp] TO [public]
GO
