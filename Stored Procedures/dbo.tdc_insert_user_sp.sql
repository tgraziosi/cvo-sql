SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_insert_user_sp] 
	@userid	VARCHAR (50), 
	@UserPw	VARCHAR(25),
	@strLocation	VARCHAR(10) = NULL,
	@strLanguage	VARCHAR(10) =  '',
	@AdminVal 	INTEGER = 0,
	@LogUserVal     INTEGER,
	@SecGroup	varchar(25),
	@mdy_format	varchar(10)
WITH ENCRYPTION

 AS

DECLARE 	
@AppUser 	AS VARCHAR(1000),
@buffer		VARCHAR(1000),
@Access		AS INTEGER,
@strDistMethod  varchar(2),
@LogUser    	varchar(2),
@ScreenSize 	varchar (10), 
@Password	VARCHAR(1000),
@source 	VARCHAR(3)


--Lets assign DEFAULT Values
IF @strDistMethod = '' OR @strDistMethod IS NULL
	BEGIN
		SELECT @strDistMethod = '01'
	END

IF @strLanguage = '' OR @strLanguage IS NULL
	BEGIN
		SELECT @strLanguage = 'us_english'
	END

--IF @LogUser = '' OR @LogUser IS NULL 
IF (@LogUserVal = 0 OR @LogUser = '' OR @LogUser IS NULL)	
	BEGIN
		SELECT @LogUser = 'N'
	END
IF @LogUserVal = 1
	BEGIN
		SELECT @LogUser = 'Y'
	END

IF @ScreenSize = '' OR @ScreenSize IS NULL
	BEGIN
		SELECT @ScreenSize = '16X20'
	END

IF @AdminVal = 0
	BEGIN
		SELECT @AppUser = 'FALSE' + @userid  
	END
ELSE IF @AdminVal = 1
	BEGIN
		SELECT @AppUser = 'TRUE ' + @userid  
	END

EXEC tdc_encrypt @UserPw, @buffer OUTPUT
SELECT @Password = @buffer

EXEC tdc_encrypt @AppUser, @buffer OUTPUT
SELECT @AppUser = @buffer

IF( SELECT COUNT(*) FROM tdc_sec (NOLOCK) WHERE UserID = @userid) = 0
	BEGIN
	/****  We want to insert a record for each module and function this user ; if they have admin rights THEN 
		Grant them admin rights to each module and function; else Granmt them the lowest security (NONE) ***/

		INSERT INTO tdc_sec (UserID, UserPW, SecGroup, Dist_Method,  Log_User, AppUser, Location, Language, mdy_format)
			VALUES(@userid, @Password, @SecGroup, @strDistMethod, @LogUser, @AppUser, @strLocation, @strLanguage, @mdy_format )

		INSERT INTO tdc_security_module (UserID, module, Source, Access)
		SELECT @userid, module, source, @AdminVal 
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
			SELECT @userid, module, [function],source, @access
			FROM tdc_security_function (NOLOCK)
			WHERE userid = 'manager'
			AND source = @source
 
			FETCH NEXT FROM tdc_sec_function_insert_cur INTO @source
		END
		CLOSE tdc_sec_function_insert_cur
		DEALLOCATE tdc_sec_function_insert_cur

	END
ELSE
	BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			RAISERROR ('The specified UserID already exists in tdc_sec.',16,1)
	
	END

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_insert_user_sp] TO [public]
GO
