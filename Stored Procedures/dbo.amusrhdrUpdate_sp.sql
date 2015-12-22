SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrhdrUpdate_sp]
(	 @timestamp timestamp,
	 @company_id smCompanyID, @user_field_id smUserFieldID, @user_field_subid int, @user_field_type smUserFieldType, @user_field_title smUserFieldTitle, @user_field_length smCounter, @validation_proc smLongDesc, @zoom_id smCounter, @min_value smMoneyZero, @max_value smMoneyZero, @selection smLongDesc, @allow_null smLogicalTrue, @default_value smStdDescription, @updated_by smUserID
) as
declare @rowcount int
declare @error int
declare @ts timestamp
declare @message varchar(255)
 


EXEC @error = amNewCoUserFields_sp @company_id
IF @error <> 0
	RETURN @error
 
update amusrhdr set
	user_field_type = @user_field_type,		
	user_field_title = @user_field_title,		
	user_field_length= @user_field_length,
	validation_proc = @validation_proc,	 
	zoom_id			 = @zoom_id,
	min_value		 = @min_value,
	max_value		 = @max_value,
	selection		 = @selection,
	allow_null		 = @allow_null,
	default_value = @default_value,			
 	updated_by		 = @updated_by,
 	last_updated	 = GETDATE()				
where company_id = @company_id 
and	 	user_field_id = @user_field_id
AND		user_field_subid		 =	 @user_field_subid	 
and timestamp = @timestamp

select @error = @@error, @rowcount = @@rowcount
if @error <> 0 
 return @error
if @rowcount = 0 
begin
 
 select 	@ts 				= timestamp 
 from 	amusrhdr 
 where	company_id 			= @company_id 
 and		user_field_id 		= @user_field_id
		AND		user_field_subid	= @user_field_subid

 select @error = @@error, @rowcount = @@rowcount
 if @error <> 0 
 return @error
 if @rowcount = 0 
 begin
 EXEC 		amGetErrorMessage_sp 20004, "tmp/amushdup.sp", 104, "amusrhdr", @error_message = @message out
 IF @message IS NOT NULL RAISERROR 	20004 @message
 RETURN 		20004
 end
 if @ts <> @timestamp
 begin
 EXEC 		amGetErrorMessage_sp 20003, "tmp/amushdup.sp", 110, "amusrhdr", @error_message = @message out
 IF @message IS NOT NULL RAISERROR 	20003 @message
 RETURN 		20003
 end
end
return @@error
GO
GRANT EXECUTE ON  [dbo].[amusrhdrUpdate_sp] TO [public]
GO
