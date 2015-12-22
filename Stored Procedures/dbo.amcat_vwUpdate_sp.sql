SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwUpdate_sp] 
( 
	@timestamp timestamp,
	@category_code smCategoryCode, 
	@category_description smStdDescription, 
	@posting_code smPostingCode,
	@posting_code_description		smStdDescription 	
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


update amcat set 
	category_description = @category_description,
	posting_code = @posting_code 
where 
	category_code = @category_code and 
	timestamp = @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amcat where 
	category_code = @category_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amcatup.sp", 92, amcat, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amcatup.sp", 98, amcat, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 

select @timestamp = timestamp 
from amcat 
where category_code = @category_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwUpdate_sp] TO [public]
GO
