SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_insert_group_sp] 
	@group_name	VARCHAR (25) , 
	@AdminVal 	INTEGER = 0

WITH ENCRYPTION

 AS

DECLARE 	
	@UserPW		VARCHAR(500),
	@AppUser 	VARCHAR(500),
	@access		INTEGER,
	@strReturn	varchar(255),
	@string 	VARCHAR(255),
	@I		INT,
	@Char		CHAR(1),
	@Asc		INT,
	@Buffer 	VARCHAR(255),
	@segment 	VARCHAR(255),
	@strlen 	VARCHAR(255),
	@source 	VARCHAR(3)

SELECT @UserPW = @group_name


IF @AdminVal = 0
	BEGIN
		SELECT @AppUser = 'FALSE' + @group_name  
	END
ELSE IF @AdminVal = 1
	BEGIN
		SELECT @AppUser = 'TRUE ' + @group_name  
	END

EXEC tdc_encrypt @UserPw, @buffer OUTPUT
SELECT @UserPw = @buffer

EXEC tdc_encrypt @AppUser, @buffer OUTPUT
SELECT @AppUser = @buffer

IF( SELECT COUNT(*) FROM tdc_sec (NOLOCK) WHERE UserID = @group_name) = 0
	BEGIN
	/****  We want to insert a record for each module and function this user ; if they have admin rights THEN 
		Grant them admin rights to each module and function; else Granmt them the lowest security (NONE) ***/

		INSERT INTO tdc_sec (UserID, UserPW, AppUser, group_flag)
			VALUES(@group_name ,	 	@UserPW , 
				@AppUser  , 		1)


		INSERT INTO tdc_security_module (UserID, module, Source, Access)
		SELECT @group_name, module, source, @AdminVal 
		FROM tdc_security_module (NOLOCK)
		WHERE [userid] = 'manager'
			
		-- Update function table
		DECLARE tdc_sec_function_insert_cur		
		CURSOR FOR SELECT source FROM tdc_app_source(NOLOCK)

		OPEN tdc_sec_function_insert_cur		

		FETCH NEXT FROM tdc_sec_function_insert_cur INTO @source
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @Source = 'CO'
				SELECT @Access = @AdminVal  
			ELSE
			BEGIN
				IF @AdminVal = 0 
					SELECT @Access = 0
				ELSE
					SELECT @Access = 2
			END
			INSERT INTO tdc_security_function (userid, module, [function],source, access)
			SELECT @group_name, module, [function],source, @access
			FROM tdc_security_function (NOLOCK)
			WHERE userid = 'manager'
			AND source = @source
 
			FETCH NEXT FROM tdc_sec_function_insert_cur INTO @source
		END
		CLOSE tdc_sec_function_insert_cur
		DEALLOCATE tdc_sec_function_insert_cur

		
		RETURN 1
	END
ELSE
	BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			RAISERROR ('Group names must be distinct, and cannot be a userid',16,1)
	
	END


GO
GRANT EXECUTE ON  [dbo].[tdc_insert_group_sp] TO [public]
GO
