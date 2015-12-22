SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_assign_user_to_group_sp]
@UserID		varchar(50),
@GroupName	varchar(50)

WITH ENCRYPTION
AS



DECLARE 
	@TempID varchar (50),
	@TempPW varchar (50),

--tdc_sec variables
	@Dist_Method char (2),
	@Trans_Method char (2),
	@Log_User char (1),
	@AppUser varchar (100),
	@GroupID varchar (50),
	@TEST varchar(25),
	@TestAdmin int,
	@strAppUser varchar (50), 
--tdc_security_function and tdc_security_module variables
	@Module varchar (50),
	@Source varchar (20),
	@Function varchar (50),
	@Access int,

--tdc_security_module variables
	@SecModSource varchar (10) 

-- Start Trans
BEGIN TRAN

--###################################################################################################################################
--Assign Group Name In  Tdc_Sec
--###################################################################################################################################

UPDATE tdc_sec SET SecGroup = @GroupName WHERE UserID = @UserID


--###################################################################################################################################
--Copy Security to Tdc_Security_Module
--###################################################################################################################################
	DECLARE Sec_Cursor INSENSITIVE CURSOR FOR
	 SELECT GroupName, Module, Source, Access             
	   FROM tdc_group_security_module (NOLOCK)
	  WHERE GroupName = @GroupName

	OPEN Sec_Cursor

	FETCH NEXT FROM Sec_Cursor 
		INTO @TempID, @Module, @SecModSource, @Access   

	WHILE (@@FETCH_STATUS = 0)
	BEGIN


		UPDATE tdc_security_module SET Access = @Access
				WHERE UserID = @UserID AND Source = @SecModSource AND Module = @Module
	
		FETCH NEXT FROM Sec_Cursor 
			INTO @TempID, @Module, @SecModSource, @Access
	END

	CLOSE Sec_Cursor
	DEALLOCATE Sec_Cursor


--###################################################################################################################################
--Copy Security to Tdc_Security_Function
--###################################################################################################################################
	DECLARE Sec_Cursor INSENSITIVE CURSOR FOR
	 SELECT GroupName, Module, Source, [Function], Access     
	   FROM tdc_group_security_function (NOLOCK)
	  WHERE GroupName = @GroupName

	OPEN Sec_Cursor

	FETCH NEXT FROM Sec_Cursor 
		INTO @TempID, @Module, @Source,@Function, @Access         

	WHILE (@@FETCH_STATUS = 0)
	BEGIN


		UPDATE tdc_security_function SET Access = @Access
				WHERE UserID = @UserID AND Module = @Module AND Source = @Source AND [Function] = @Function
	
		FETCH NEXT FROM Sec_Cursor 
			INTO @TempID, @Module, @Source, @Function, @Access
	END

	CLOSE Sec_Cursor
	DEALLOCATE Sec_Cursor


	IF (@@ERROR <> 0)
		BEGIN
			ROLLBACK TRAN
			RETURN
		END

	COMMIT TRAN


GO
GRANT EXECUTE ON  [dbo].[tdc_assign_user_to_group_sp] TO [public]
GO
