SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amNewCoUserFields_sp]
(	 @company_id	smCompanyID 
) as

DECLARE @tbl_id				int,
		@alt_tbl_id		 	int,
	 	@error 				int,
		@message 			varchar(255),
		@count				int



BEGIN TRANSACTION


SELECT	@tbl_id			= tbl_id
FROM	amtblhdr 
WHERE	tbl_name 		= "amusrfld"

IF @tbl_id IS NULL 
BEGIN

	EXEC 		amGetErrorMessage_sp 20208, "tmp/amnewfld.sp", 75, "amusrfld", @error_message = @message out
 IF @message IS NOT NULL RAISERROR 	20208 @message
	ROLLBACK 	TRANSACTION
 RETURN 		20208
	
END	 



SELECT	@alt_tbl_id		= tbl_alt_id
FROM	amtblalt 
WHERE	tbl_id 			= @tbl_id
AND		alt_key 		= @company_id 


IF @alt_tbl_id IS NULL 
BEGIN

	EXEC 		amGetErrorMessage_sp 20208, "tmp/amnewfld.sp", 95, "amtblalt", @error_message = @message out
 IF @message IS NOT NULL RAISERROR 	20208 @message
	ROLLBACK 	TRANSACTION
 RETURN 		20208
	
END	


IF @tbl_id <> @alt_tbl_id 
BEGIN
	ROLLBACK TRANSACTION
	RETURN 0
END



SELECT @count = 1
WHILE EXISTS(SELECT tbl_id FROM amtblfld WHERE tbl_id = @count + @tbl_id)
BEGIN
	SELECT @count = @count + 1
END

SELECT @alt_tbl_id = @tbl_id + @count



UPDATE amtblalt
SET 	tbl_alt_id 	= @alt_tbl_id,
		system_defined = 0
WHERE	alt_key 	= @company_id
AND		tbl_id		= @tbl_id

 
SELECT @error = @@error
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION
	RETURN @error
END


INSERT amtblfld(
		system_defined,
		tbl_id,
		fld_id,
		length,
		s_type,
		key_nr,
		key_fixed,
		null_allow,
		popup_mnu,
		zoom_id,
		name,
		fld_default,
		validation_proc,
		foreign_key
		)

SELECT 	0,
		@alt_tbl_id,
		fld_id,
		length,
		s_type,
		key_nr,
		key_fixed,
		null_allow,
		popup_mnu,
		zoom_id,
		name,
		fld_default,
		validation_proc,
		foreign_key
FROM 	amtblfld
WHERE	tbl_id	= @tbl_id

SELECT @error = @@error
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION
	RETURN @error
END

 
COMMIT TRANSACTION
return @@error
GO
GRANT EXECUTE ON  [dbo].[amNewCoUserFields_sp] TO [public]
GO
